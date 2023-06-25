// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721PressDatabaseV1} from "../../src/core/token/ERC721/database/ERC721PressDatabaseV1.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationMetadataRenderer} from "../../src/strategies/curation/renderer/CurationMetadataRenderer.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

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

    function test_mintWithData() public setUpCurationStrategy {
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

    function test_mintBurnSort() public setUpCurationStrategy {
        // setup tokens
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

        // setup non-zero sort values for testing

        uint256[] memory burnIds_1 = new uint256[](1);
        burnIds_1[0] = 1;
        uint256[] memory burnIds_2 = new uint256[](1);
        burnIds_2[0] = 2;
        uint256[] memory burnIds_3 = new uint256[](1);
        burnIds_3[0] = 3;
        uint256[] memory burnIds_4 = new uint256[](2);
        burnIds_4[0] = 4;                        
        burnIds_4[1] = 6;                                             
        int96[] memory sortOrders = new int96[](2);
        sortOrders[0] = 1;
        sortOrders[1] = 2;   

        // setup zero values for testing
        uint256 zeroQuantity = 0;
        bytes memory zeroData = new bytes(0);
        uint256[] memory zeroBurns = new uint256[](0);
        uint256[] memory zeroSortIds = new uint256[](0);
        int96[] memory zeroSortOrders = new int96[](0);

        // minting
        targetPressProxy.mintBurnSort(
            2, // mintQuantity
            encodedListings, // mintData
            zeroBurns,
            zeroSortIds,
            zeroSortOrders
        );        

        // NOTE: the following function calls happen in scopes to avoid stack too deep errors
        //      caused by introducing too many storage variables

        // sorting
        {
            uint256[] memory sortIds_1 = new uint256[](2);
            sortIds_1[0] = 1;
            sortIds_1[1] = 2;            
            targetPressProxy.mintBurnSort(
                zeroQuantity, // mintQuantity
                zeroData, // mintData
                zeroBurns,
                sortIds_1,
                sortOrders
            );     
        }                       

        // burning  
        targetPressProxy.mintBurnSort(
            zeroQuantity, // mintQuantity
            zeroData, // mintData
            burnIds_1,
            zeroSortIds,
            zeroSortOrders
        );             

        // minting and sorting
        {
            uint256[] memory sortIds_2 = new uint256[](2);
            sortIds_2[0] = 3;
            sortIds_2[1] = 4;        
            targetPressProxy.mintBurnSort(
                2, // mintQuantity
                encodedListings, // mintData
                zeroBurns,
                sortIds_2,
                sortOrders
            );                            
        }

        // minting and burning
        targetPressProxy.mintBurnSort(
            2, // mintQuantity
            encodedListings, // mintData
            burnIds_2,
            zeroSortIds,
            zeroSortOrders
        );                 

        // sorting and burning
        {
            uint256[] memory sortIds_3 = new uint256[](2);
            sortIds_3[0] = 5;
            sortIds_3[1] = 6;       
            targetPressProxy.mintBurnSort(
                zeroQuantity, // mintQuantity
                zeroData, // mintData
                burnIds_3,
                sortIds_3,
                sortOrders
            );                      
        }

        // mintBurnSort
        {
            uint256[] memory sortIds_4 = new uint256[](2);
            sortIds_4[0] = 7;
            sortIds_4[1] = 8;    
            targetPressProxy.mintBurnSort(
                2, // mintQuantity
                encodedListings, // mintData
                burnIds_4,
                sortIds_4,
                sortOrders
            );                        
        }

        (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        // length should be 3 as 8 tokens were minted and 5 burned
        require(tokenData.length == 3, "incorrect token length");

        (IERC721PressDatabase.TokenDataRetrieved memory token5_data) = database.readData(address(targetPressProxy), 5);
        (IERC721PressDatabase.TokenDataRetrieved memory token7_data) = database.readData(address(targetPressProxy), 7);
        (IERC721PressDatabase.TokenDataRetrieved memory token8_data) = database.readData(address(targetPressProxy), 8);

        require(keccak256(tokenData[0].storedData) == keccak256(token5_data.storedData), "token 5 data storage incorrect");
        require(keccak256(tokenData[1].storedData) == keccak256(token7_data.storedData), "token 7 data storage incorrect");
        require(keccak256(tokenData[2].storedData) == keccak256(token8_data.storedData), "token 8 data storage incorrect");

        require(tokenData[0].sortOrder == token5_data.sortOrder, "token 5 sortOrder incorrect");
        require(tokenData[1].sortOrder == token7_data.sortOrder, "token 5 sortOrder incorrect");        
        require(tokenData[2].sortOrder == token8_data.sortOrder, "token 5 sortOrder incorrect");        
    }

    function test_setSettings() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");        
        targetPressProxy.setSettings(payable(address(0x12345)), 300);   
        (IERC721Press.Settings memory newSettings) = targetPressProxy.getSettings();
        require(newSettings.fundsRecipient == payable(address(0x12345)), "funds recipient set incorrectly");
        require(newSettings.royaltyBPS == 300, "funds recipient set incorrectly");           
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER does not have access to setSettings function
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        targetPressProxy.setSettings(payable(address(0x12345)), 300);   
    }     

    function test_royaltyInfo() public setUpCurationStrategy {
        uint256 priceInWei = 100000000000000000; // 0.1 eth
        uint256 precalculatedRoyalty = priceInWei * 250 / 10_000; // 0.1 eth * 2.5% royalty = 0.0025 eth aka 2500000000000000 wei
        (address receiver, uint256 expectedRoyaltyValue) = targetPressProxy.royaltyInfo(1, priceInWei);
        require(precalculatedRoyalty == expectedRoyaltyValue, "royalties not calculated correctly");
    }         

    function test_mintWithData_paymentRouting() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // set up mock logic for tests
        MockLogic mockLogic = new MockLogic();
        bytes memory mockLogicInit = "0x12345";
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);
        vm.stopPrank();

        // mockLogic mint price check + fetch
        mockLogic.getMintPrice(address(0x123), address(0x123), 1);
        uint256 totalMintPrice = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).totalMintPrice(
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

    /* TODO
    * 4. add tests for upgrades + transfers
    * 5. do factory impl + tests
    * 6. deploys ???
    * 7. first pass diagrams
    */      
}