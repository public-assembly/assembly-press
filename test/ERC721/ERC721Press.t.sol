// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV1} from "../../src/strategies/curation/database/CurationDatabaseV1.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationRendererV1} from "../../src/strategies/curation/renderer/CurationRendererV1.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

contract ERC721PressTest is ERC721PressConfig {

    function test_initialize() public setUpCurationStrategy {
        
        // testing local press storage
        require(keccak256(bytes(targetPressProxy.name())) == keccak256(bytes("Public Assembly")), "incorrect name");
        require(keccak256(bytes(targetPressProxy.symbol())) == keccak256(bytes("PA")), "incorrect symbol");
        require(targetPressProxy.getDatabase() == database, "incorrect database");
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");
        require(pressSettings.transferable == false, "token transferability set incorrectly");

        // check to see if supportsInterface work
        require(targetPressProxy.supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support");
        require(targetPressProxy.supportsInterface(type(IERC5192).interfaceId) == true, "doesn't support");    

        // check to make sure contract cant be reinitialized
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        targetPressProxy.initialize({
            name: "THIS SHOULDNT WORK",
            symbol: "TSW",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            database: database,
            databaseInit: bytes("123"),
            settings: pressSettings                         
        });                    
    }

    function test_mint_1_WithData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](1);        
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;            
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 1, "mint not functioning correctly");   
    }     

    function test_mint_2_WithData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](2);        
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        listings[1].chainId = 7777777;       
        listings[1].tokenId = 0;              
        listings[1].listingAddress = address(0x54321);               
        listings[1].hasTokenId = false;      
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(2, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 2, "mint not functioning correctly");   
    } 

    function test_mintWithMaliciousData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        bytes[] memory encodedListings = new bytes[](2);   
        encodedListings[0] = abi.encode(5);
        encodedListings[1] = abi.encode(8);        
        bytes memory encodedEncodedListings = abi.encode(encodedListings);   
        // should revert because data being passed does not fit Listing struct
        vm.expectRevert();        
        targetPressProxy.mintWithData(2, encodedEncodedListings);           
    }

    function test_sort() public setUpCurationStrategy() {
        
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");   

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](2);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        listings[1].chainId = 7777777;       
        listings[1].tokenId = 0;              
        listings[1].listingAddress = address(0x54321);               
        listings[1].hasTokenId = false;    
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(2, encodedListings);

        // setup + call sort         

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;        

        int96[] memory sortOrders = new int96[](2);
        sortOrders[0] = 1;
        sortOrders[1] = -1;

        targetPressProxy.sort(tokenIds, sortOrders);

        // checks that sortOrders generated correctly in readAllData call as well
        (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        require(tokenData[0].sortOrder == sortOrders[0], "sort order should be 1 here");
        require(tokenData[1].sortOrder == sortOrders[1], "sort order should be -1 here");
    } 

    function test_overwrite() public setUpCurationStrategy_MutableMetadata() {
        
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");   

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory initialTokenData = new PartialListing[](2);
        initialTokenData[0].chainId = 1;       
        initialTokenData[0].tokenId = 3;      
        initialTokenData[0].listingAddress = address(0x12345);       
        initialTokenData[0].hasTokenId = true;       
        initialTokenData[1].chainId = 7777777;       
        initialTokenData[1].tokenId = 0;              
        initialTokenData[1].listingAddress = address(0x54321);               
        initialTokenData[1].hasTokenId = false;    
        bytes memory initialEncodedListings = encodeListingArray(initialTokenData);
        targetPressProxy.mintWithData(2, initialEncodedListings);

        (IERC721PressDatabase.TokenDataRetrieved[] memory initialDatabaseReturn) = database.readAllData(address(targetPressProxy));

        require(keccak256(initialDatabaseReturn[0].storedData) == keccak256(abi.encode(initialTokenData[0].chainId, initialTokenData[0].tokenId, initialTokenData[0].listingAddress, initialTokenData[0].hasTokenId)), "token #1 data stored incorrectly");        
        require(keccak256(initialDatabaseReturn[1].storedData) == keccak256(abi.encode(initialTokenData[1].chainId, initialTokenData[1].tokenId, initialTokenData[1].listingAddress, initialTokenData[1].hasTokenId)), "token #2 data stored incorrectly");        

        string memory tokenURI_1_initial = targetPressProxy.tokenURI(1);
        string memory tokenURI_2_initial = targetPressProxy.tokenURI(2);
        
        // structure new data to overwrite tokens with
        PartialListing[] memory newTokenData = new PartialListing[](2);
        newTokenData[0].chainId = 4;       
        newTokenData[0].tokenId = 7;      
        newTokenData[0].listingAddress = address(0x6501);       
        newTokenData[0].hasTokenId = true;       
        newTokenData[1].chainId = 666;       
        newTokenData[1].tokenId = 0;              
        newTokenData[1].listingAddress = address(0x82d4);               
        newTokenData[1].hasTokenId = false;    
        bytes memory newEncodedListing_1 = abi.encode(newTokenData[0].chainId, newTokenData[0].tokenId, newTokenData[0].listingAddress, newTokenData[0].hasTokenId);
        bytes memory newEncodedListing_2 = abi.encode(newTokenData[1].chainId, newTokenData[1].tokenId, newTokenData[1].listingAddress, newTokenData[1].hasTokenId);
        // overwrite() takes in calldata arrays but you can pass in memory arrays as they are treated as calldata if specified in the function
        bytes[] memory overwriteDataArray = new bytes[](2);
        overwriteDataArray[0] = newEncodedListing_1;
        overwriteDataArray[1] = newEncodedListing_2;
        uint256[] memory tokenIdArray = new uint256[](2);
        tokenIdArray[0] = 1;
        tokenIdArray[1] = 2;        
        targetPressProxy.overwrite(tokenIdArray, overwriteDataArray);
        (IERC721PressDatabase.TokenDataRetrieved[] memory newDatabaseReturn) = database.readAllData(address(targetPressProxy));
        require(keccak256(bytes(targetPressProxy.tokenURI(1))) != keccak256(bytes(tokenURI_1_initial)), "tokenURI #1 should be different after data overwrite");              
        require(keccak256(bytes(targetPressProxy.tokenURI(2))) != keccak256(bytes(tokenURI_2_initial)), "tokenURI #1 should be different after data overwrite");              
    }     

    function test_burn() public setUpCurationStrategy() {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](3);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        listings[1].chainId = 7777777;       
        listings[1].tokenId = 0;              
        listings[1].listingAddress = address(0x54321);               
        listings[1].hasTokenId = false;    
        listings[2].chainId = 100;       
        listings[2].tokenId = 2;              
        listings[2].listingAddress = address(0xbd720);               
        listings[2].hasTokenId = true;            
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(3, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 3, "mint not functioning correctly");  
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");         
        require(targetPressProxy.ownerOf(2) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");         
        require(targetPressProxy.ownerOf(3) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");         
        require(targetPressProxy.exists(1) == true, "incorrect exists return");
        require(targetPressProxy.exists(2) == true, "incorrect exists return");
        require(targetPressProxy.exists(3) == true, "incorrect exists return");
        
        targetPressProxy.burn(1);
        // ownerOf should revert if token does not exist anymore post burn
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(1);
        require(targetPressProxy.exists(1) == false, "exists should be false after burn");  

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 2;
        tokenIds[1] = 3;
        targetPressProxy.burnBatch(tokenIds);
        // ownerOf should revert if token does not exist anymore post burn
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(2);        
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(3);                
        require(targetPressProxy.exists(3) == false, "exists should be false after burn");  
        require(targetPressProxy.exists(3) == false, "exists should be false after burn");  
    }

    function test_mintSortOverwriteBurn() public setUpCurationStrategy_MutableMetadata() {
        // setup tokens
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](4);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        listings[1].chainId = 7777777;       
        listings[1].tokenId = 0;              
        listings[1].listingAddress = address(0x54321);               
        listings[1].hasTokenId = false;    
        listings[2].chainId = 124;       
        listings[2].tokenId = 5;              
        listings[2].listingAddress = address(0xab59);               
        listings[2].hasTokenId = true;    
        listings[3].chainId = 59019;       
        listings[3].tokenId = 0;              
        listings[3].listingAddress = address(0xf989);               
        listings[3].hasTokenId = false;                    
        bytes memory encodedListings = encodeListingArray(listings);

        // setup non-zero sort values for testing

        uint256[] memory burnIds = new uint256[](2);
        burnIds[0] = 1;
        burnIds[1] = 2;    

        uint256[] memory sortIds = new uint256[](2);
        sortIds[0] = 3;
        sortIds[1] = 4;        
                                       
        int96[] memory sortOrders = new int96[](2);
        sortOrders[0] = 1000;
        sortOrders[1] = -1000;   

        {
            // structure overwriteIds array
            uint256[] memory overwriteIds = new uint256[](2);
            overwriteIds[0] = 3;
            overwriteIds[1] = 4;    
            // structure new data to overwrite tokens with
            PartialListing[] memory newTokenData = new PartialListing[](2);
            newTokenData[0].chainId = 4;       
            newTokenData[0].tokenId = 7;      
            newTokenData[0].listingAddress = address(0x6501);       
            newTokenData[0].hasTokenId = true;       
            newTokenData[1].chainId = 666;       
            newTokenData[1].tokenId = 0;              
            newTokenData[1].listingAddress = address(0x82d4);               
            newTokenData[1].hasTokenId = false;    
            bytes memory newEncodedListing_1 = abi.encode(newTokenData[0].chainId, newTokenData[0].tokenId, newTokenData[0].listingAddress, newTokenData[0].hasTokenId);
            bytes memory newEncodedListing_2 = abi.encode(newTokenData[1].chainId, newTokenData[1].tokenId, newTokenData[1].listingAddress, newTokenData[1].hasTokenId);
            // overwrite() takes in calldata arrays but you can pass in memory arrays as they are treated as calldata if specified in the function
            bytes[] memory overwriteDataArray = new bytes[](2);
            overwriteDataArray[0] = newEncodedListing_1;   
            overwriteDataArray[1] = newEncodedListing_2;   

            // call `mintSortOverwriteBurn`         
            targetPressProxy.mintSortOverwriteBurn(
                IERC721Press.MintParams({
                    quantity: 4,
                    data: encodedListings
                }),
                IERC721Press.SortParams({
                    tokenIds: sortIds,
                    sortOrders: sortOrders
                }),
                IERC721Press.OverwriteParams({
                    tokenIds: overwriteIds,
                    newData: overwriteDataArray
                }),
                IERC721Press.BurnParams({
                    tokenIds: burnIds
                })                                                
            );                     
        }

        // (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        // // length should be 3 as 8 tokens were minted and 5 burned
        // require(tokenData.length == 3, "incorrect token length");

        // (IERC721PressDatabase.TokenDataRetrieved memory token5_data) = database.readData(address(targetPressProxy), 5);
        // (IERC721PressDatabase.TokenDataRetrieved memory token7_data) = database.readData(address(targetPressProxy), 7);
        // (IERC721PressDatabase.TokenDataRetrieved memory token8_data) = database.readData(address(targetPressProxy), 8);

        // require(keccak256(tokenData[0].storedData) == keccak256(token5_data.storedData), "token 5 data storage incorrect");
        // require(keccak256(tokenData[1].storedData) == keccak256(token7_data.storedData), "token 7 data storage incorrect");
        // require(keccak256(tokenData[2].storedData) == keccak256(token8_data.storedData), "token 8 data storage incorrect");

        // require(tokenData[0].sortOrder == token5_data.sortOrder, "token 5 sortOrder incorrect");
        // require(tokenData[1].sortOrder == token7_data.sortOrder, "token 5 sortOrder incorrect");        
        // require(tokenData[2].sortOrder == token8_data.sortOrder, "token 5 sortOrder incorrect");        
    }    

    // function test_mintBurnSort() public setUpCurationStrategy {
    //     // setup tokens
    //     vm.startPrank(PRESS_ADMIN_AND_OWNER);       
    //     PartialListing[] memory listings = new PartialListing[](2);
    //     listings[0].chainId = 1;       
    //     listings[0].tokenId = 3;      
    //     listings[0].listingAddress = address(0x12345);       
    //     listings[0].hasTokenId = true;       
    //     listings[1].chainId = 7777777;       
    //     listings[1].tokenId = 0;              
    //     listings[1].listingAddress = address(0x54321);               
    //     listings[1].hasTokenId = false;    
    //     bytes memory encodedListings = encodeListingArray(listings);

    //     // setup non-zero sort values for testing

    //     uint256[] memory burnIds_1 = new uint256[](1);
    //     burnIds_1[0] = 1;
    //     uint256[] memory burnIds_2 = new uint256[](1);
    //     burnIds_2[0] = 2;
    //     uint256[] memory burnIds_3 = new uint256[](1);
    //     burnIds_3[0] = 3;
    //     uint256[] memory burnIds_4 = new uint256[](2);
    //     burnIds_4[0] = 4;                        
    //     burnIds_4[1] = 6;                                             
    //     int96[] memory sortOrders = new int96[](2);
    //     sortOrders[0] = 1;
    //     sortOrders[1] = 2;   

    //     // setup zero values for testing
    //     uint256 zeroQuantity = 0;
    //     bytes memory zeroData = new bytes(0);
    //     uint256[] memory zeroBurns = new uint256[](0);
    //     uint256[] memory zeroSortIds = new uint256[](0);
    //     int96[] memory zeroSortOrders = new int96[](0);

    //     // minting
    //     targetPressProxy.mintBurnSort(
    //         2, // mintQuantity
    //         encodedListings, // mintData
    //         zeroBurns,
    //         zeroSortIds,
    //         zeroSortOrders
    //     );        

    //     // NOTE: the following function calls happen in scopes to avoid stack too deep errors
    //     //      caused by introducing too many storage variables

    //     // sorting
    //     {
    //         uint256[] memory sortIds_1 = new uint256[](2);
    //         sortIds_1[0] = 1;
    //         sortIds_1[1] = 2;            
    //         targetPressProxy.mintBurnSort(
    //             zeroQuantity, // mintQuantity
    //             zeroData, // mintData
    //             zeroBurns,
    //             sortIds_1,
    //             sortOrders
    //         );     
    //     }                       

    //     // burning  
    //     targetPressProxy.mintBurnSort(
    //         zeroQuantity, // mintQuantity
    //         zeroData, // mintData
    //         burnIds_1,
    //         zeroSortIds,
    //         zeroSortOrders
    //     );             

    //     // minting and sorting
    //     {
    //         uint256[] memory sortIds_2 = new uint256[](2);
    //         sortIds_2[0] = 3;
    //         sortIds_2[1] = 4;        
    //         targetPressProxy.mintBurnSort(
    //             2, // mintQuantity
    //             encodedListings, // mintData
    //             zeroBurns,
    //             sortIds_2,
    //             sortOrders
    //         );                            
    //     }

    //     // minting and burning
    //     targetPressProxy.mintBurnSort(
    //         2, // mintQuantity
    //         encodedListings, // mintData
    //         burnIds_2,
    //         zeroSortIds,
    //         zeroSortOrders
    //     );                 

    //     // sorting and burning
    //     {
    //         uint256[] memory sortIds_3 = new uint256[](2);
    //         sortIds_3[0] = 5;
    //         sortIds_3[1] = 6;       
    //         targetPressProxy.mintBurnSort(
    //             zeroQuantity, // mintQuantity
    //             zeroData, // mintData
    //             burnIds_3,
    //             sortIds_3,
    //             sortOrders
    //         );                      
    //     }

    //     // mintBurnSort
    //     {
    //         uint256[] memory sortIds_4 = new uint256[](2);
    //         sortIds_4[0] = 7;
    //         sortIds_4[1] = 8;    
    //         targetPressProxy.mintBurnSort(
    //             2, // mintQuantity
    //             encodedListings, // mintData
    //             burnIds_4,
    //             sortIds_4,
    //             sortOrders
    //         );                        
    //     }

    //     (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
    //     // length should be 3 as 8 tokens were minted and 5 burned
    //     require(tokenData.length == 3, "incorrect token length");

    //     (IERC721PressDatabase.TokenDataRetrieved memory token5_data) = database.readData(address(targetPressProxy), 5);
    //     (IERC721PressDatabase.TokenDataRetrieved memory token7_data) = database.readData(address(targetPressProxy), 7);
    //     (IERC721PressDatabase.TokenDataRetrieved memory token8_data) = database.readData(address(targetPressProxy), 8);

    //     require(keccak256(tokenData[0].storedData) == keccak256(token5_data.storedData), "token 5 data storage incorrect");
    //     require(keccak256(tokenData[1].storedData) == keccak256(token7_data.storedData), "token 7 data storage incorrect");
    //     require(keccak256(tokenData[2].storedData) == keccak256(token8_data.storedData), "token 8 data storage incorrect");

    //     require(tokenData[0].sortOrder == token5_data.sortOrder, "token 5 sortOrder incorrect");
    //     require(tokenData[1].sortOrder == token7_data.sortOrder, "token 5 sortOrder incorrect");        
    //     require(tokenData[2].sortOrder == token8_data.sortOrder, "token 5 sortOrder incorrect");        
    // }

    function test_updateSettings() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");        
        targetPressProxy.updateSettings(payable(address(0x12345)), 300);   
        (IERC721Press.Settings memory newSettings) = targetPressProxy.getSettings();
        require(newSettings.fundsRecipient == payable(address(0x12345)), "funds recipient set incorrectly");
        require(newSettings.royaltyBPS == 300, "funds recipient set incorrectly");           
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER does not have access to updateSettings function
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        targetPressProxy.updateSettings(payable(address(0x12345)), 300);   
    }     

    function test_royaltyInfo() public setUpCurationStrategy {
        uint256 priceInWei = 100000000000000000; // 0.1 eth
        uint256 precalculatedRoyalty = priceInWei * 250 / 10_000; // 0.1 eth * 2.5% royalty = 0.0025 eth aka 2500000000000000 wei
        (address receiver, uint256 expectedRoyaltyValue) = targetPressProxy.royaltyInfo(1, priceInWei);
        require(precalculatedRoyalty == expectedRoyaltyValue, "royalties not calculated correctly");
    }         

    function test_paymentRouting() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // set up mock logic for tests
        MockLogic mockLogic = new MockLogic();
        bytes memory mockLogicInit = "0x12345";
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);
        vm.stopPrank();

        // mockLogic mint price check + fetch
        mockLogic.getMintPrice(address(0x123), address(0x123), 1);
        uint256 totalMintPrice = CurationDatabaseV1(address(targetPressProxy.getDatabase())).totalMintPrice(
            address(targetPressProxy), 
            msg.sender, 
            1
        );        

        // get funds recipient + deal funds to minter
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();        
        vm.deal(PRESS_USER, 1 ether);

        vm.startPrank(PRESS_USER);
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData{
            value: totalMintPrice
        }(1, encodedListings);
        require(
            PRESS_USER.balance == (1 ether - totalMintPrice), "incorrect eth balance of minter"
        );
        require(
            pressSettings.fundsRecipient.balance == totalMintPrice, "incorrect eth balance of funds recipient"
        );        
    }    

    function test_nonTransferableTokens() public setUpCurationStrategy {
        
        // confirm token transferability set to false
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == false, "token transferability set incorrectly");        
        
        vm.startPrank(PRESS_ADMIN_AND_OWNER);         
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should revert because Press is set to have non transferable tokens
        vm.expectRevert(abi.encodeWithSignature("Non_Transferrable_Token()"));
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, address(0x123), 1, new bytes(0));        
    }         

    function test_transferableTokens() public setUpCurationStrategy_TransferableTokens() {
        
        // confirm token transferability set to true
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == true, "token transferability set incorrectly");        
        
        vm.startPrank(PRESS_ADMIN_AND_OWNER);         
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should NOT revert because Press is set to have transferable tokens
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, PRESS_USER, 1, new bytes(0));        
        require(targetPressProxy.ownerOf(1) == PRESS_USER, "incorrect tokenOwner");
    }             

    function test_transferPressOwnership() public setUpCurationStrategy {
        vm.startPrank(PRESS_USER);
        // expect revert on transfer because msg.sender is not owner
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        targetPressProxy.transferOwnership(PRESS_USER);
        vm.stopPrank();
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // transfer should go through since being called from contract owner
        targetPressProxy.transferOwnership(PRESS_USER);
        require(targetPressProxy.owner() == PRESS_USER, "ownership not transferred correctly");
    }    

    // TODO: add in a test upgrading Press Proxy to a new implementation
    // *
    // *
    // *
    // *
    // *


    // Tests with more optimal data passing
    // 07/04/2023

    struct ModifiedListing {
        uint256 chainId;
        uint256 tokenId;
        address listingAddress;
        uint8 hasTokenId;
    }

    function test_BytesUtils() public {

        ModifiedListing memory listing = ModifiedListing({
            chainId: 1,
            tokenId: 2,
            listingAddress: 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170,
            hasTokenId: 1
        });

        bytes memory packedListing = abi.encodePacked(
            listing.chainId,
            listing.tokenId,
            listing.listingAddress,
            listing.hasTokenId
        );

        uint256 decodedChainId = BytesLib.toUint256(packedListing, 0);
        require(decodedChainId == listing.chainId, "chainId encoding didnt work");

        uint256 decodedtokenId = BytesLib.toUint256(packedListing, 32);
        require(decodedtokenId== listing.tokenId, "tokenIdencoding didnt work");        

        address decodedListingAddress = BytesLib.toAddress(packedListing, 64);
        require(decodedListingAddress == listing.listingAddress, "listingAddress encoding didnt work");       

        uint8 decodedHasTokenId = BytesLib.toUint8(packedListing, 84);
        require(decodedHasTokenId == listing.hasTokenId, "decodedHasTokenId encoding didnt work");        



        // uint256 value = 7;
        // bytes memory uint256_Test = abi.encodePacked(value);
        // uint256 decoded = BytesLib.toUint256(uint256_Test, 0);
        // require(decoded == 7, "didnt work");
    }

    function test_constructListing() public {

        ModifiedListing memory listing = ModifiedListing({
            chainId: 1,
            tokenId: 2,
            listingAddress: 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170,
            hasTokenId: 1
        });

        bytes memory packedListing = abi.encodePacked(
            listing.chainId,
            listing.tokenId,
            listing.listingAddress,
            listing.hasTokenId
        );

        ModifiedListing memory reconstructedListing = ModifiedListing({
            chainId: BytesLib.toUint256(packedListing, 0),
            tokenId: BytesLib.toUint256(packedListing, 32),
            listingAddress: BytesLib.toAddress(packedListing, 64),
            hasTokenId: BytesLib.toUint8(packedListing, 84)
        });

        require(reconstructedListing.chainId == listing.chainId, "chainId encoding didnt work");
        require(reconstructedListing.tokenId == listing.tokenId, "tokenIdencoding didnt work");        
        require(reconstructedListing.listingAddress == listing.listingAddress, "listingAddress encoding didnt work");       
        require(reconstructedListing.hasTokenId == listing.hasTokenId, "decodedHasTokenId encoding didnt work");  
    }
}