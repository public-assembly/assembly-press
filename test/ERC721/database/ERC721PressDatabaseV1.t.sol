// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "../utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721PressDatabaseV1} from "../../../src/core/token/ERC721/database/ERC721PressDatabaseV1.sol";
import {IERC5192} from "../../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationMetadataRenderer} from "../../../src/strategies/curation/renderer/CurationMetadataRenderer.sol";

import {MockERC721} from "../utils/mocks/MockERC721.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract ERC721PressDatabaseV1Test is ERC721PressConfig {

    function test_initialize() public setUpCurationStrategy {
        
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");
        
        // check database storage on initialization
        (
            uint256 storedCounter,
            address pressLogic,
            uint8 initialized,
            address pressRenderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));      

        require(storedCounter == 0, "stored counter should be zero since no mints have occurred");
        require(pressLogic == address(logic), "press logic initialized in database incorrectly");
        require(initialized == 1, "initialized should equal 1 post initialization");
        require(pressRenderer == address(renderer), "press renderer initialized in database incorrectly");

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
        // array of structs that look like {bytes storedData, int96 sortOrder}
        (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        require(keccak256(tokenData[0].storedData) == keccak256(abi.encode(listings[0].chainId, listings[0].tokenId, listings[0].listingAddress, listings[0].hasTokenId)), "token #1 data not stored properly");
        require(tokenData[0].sortOrder == 0, "sort order should be zero here");
        require(keccak256(tokenData[1].storedData) == keccak256(abi.encode(listings[1].chainId, listings[1].tokenId, listings[1].listingAddress, listings[1].hasTokenId)), "token #2 data not stored properly");                
        require(tokenData[1].sortOrder == 0, "sort order should be zero here");

        // process PRESS_USER mints for later checks
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        targetPressProxy.mintWithData(2, encodedListings);
        targetPressProxy.mintWithData(2, encodedListings);        
        vm.stopPrank();

        // check access for expected scenarios for this initialization strategy
        // PRESS_ADMIN_AND_OWNER
        require(database.canMint(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 3) == true, "admin minter caller should have different access");
        require(database.canBurn(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 1) == true, "admin burn caller should have different access");
        require(database.canSort(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true, "admin sort caller should have different access");
        require(database.canEditSettings(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true, "admin settings caller should have different access");
        require(database.canEditContractData(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true, "admin contract data caller should have different access");
        require(database.canEditTokenData(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 1) == false, "admin token data caller should have different access");
        require(database.canEditPayments(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true, "admin payments caller should have different access");            
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // burn should process since PRESS_ADMIN_AND_OWNER is owner of token being burned
        targetPressProxy.burn(1);       
        // burn should process since PRESS_ADMIN_AND_OWNER is NOT owner of token being burned but DOES have override access 
        targetPressProxy.burn(3);       
        vm.stopPrank();           
        
        // PRESS_MANAGER (manager has admin esque burn access)
        require(database.canMint(address(targetPressProxy), PRESS_MANAGER, 3) == true, "manager mint caller should have different access");
        require(database.canBurn(address(targetPressProxy), PRESS_MANAGER, 1) == true, "manager burn caller should have different access");
        require(database.canSort(address(targetPressProxy), PRESS_MANAGER) == true, "manager sort caller should have different access");
        require(database.canEditSettings(address(targetPressProxy), PRESS_MANAGER) == false, "manager settings caller should have different access");
        require(database.canEditContractData(address(targetPressProxy), PRESS_MANAGER) == true, "manager contract data caller should have different access");
        require(database.canEditTokenData(address(targetPressProxy), PRESS_MANAGER, 1) == false, "manager token data caller should have different access");
        require(database.canEditPayments(address(targetPressProxy), PRESS_MANAGER) == false, "manager payments caller should have different access");        
        vm.startPrank(PRESS_MANAGER);
        targetPressProxy.mintWithData(2, encodedListings);
        // burn should process since PRESS_MANAGER is owner of token being burned
        targetPressProxy.burn(7);       
        // burn should process since PRESS_MANAGER is NOT owner of token being burned but DOES have override access 
        targetPressProxy.burn(5);       
        vm.stopPrank();

        // PRESS_USER
        require(database.canMint(address(targetPressProxy), PRESS_USER, 3) == true, "user mint caller should have different access");
        require(database.canBurn(address(targetPressProxy), PRESS_USER, 1) == false, "user burn caller should have different access");
        require(database.canSort(address(targetPressProxy), PRESS_USER) == false, "user sort caller should have different access");
        require(database.canEditSettings(address(targetPressProxy), PRESS_USER) == false, "user settings caller should have different access");
        require(database.canEditContractData(address(targetPressProxy), PRESS_USER) == false, "user contract data caller should have different access");
        require(database.canEditTokenData(address(targetPressProxy), PRESS_USER, 1) == false, "user token data caller should have different access");
        require(database.canEditPayments(address(targetPressProxy), PRESS_USER) == false, "user payments caller should have different access");        
        vm.startPrank(PRESS_USER);
        targetPressProxy.mintWithData(2, encodedListings);
        // burn should process since PRESS_USER is owner of token being burned
        targetPressProxy.burn(6);
        vm.expectRevert(abi.encodeWithSignature("No_Burn_Access()"));
        // burn should revert since PRESS_USER is NOT owner of token being burned and doesnt have override access
        targetPressProxy.burn(2);
        vm.stopPrank();

        // PRESS_NO_ROLE
        require(database.canMint(address(targetPressProxy), PRESS_NO_ROLE_1, 3) == false, "non-user mint caller should have different access");
        require(database.canBurn(address(targetPressProxy), PRESS_NO_ROLE_1, 1) == false, "non-user burn caller should have different access");
        require(database.canSort(address(targetPressProxy), PRESS_NO_ROLE_1) == false, "non-user sort caller should have different access");
        require(database.canEditSettings(address(targetPressProxy), PRESS_NO_ROLE_1) == false, "non-user settings caller should have different access");
        require(database.canEditContractData(address(targetPressProxy), PRESS_NO_ROLE_1) == false, "non-user contract data caller should have different access");
        require(database.canEditTokenData(address(targetPressProxy), PRESS_NO_ROLE_1, 1) == false, "non-user token data caller should have different access");
        require(database.canEditPayments(address(targetPressProxy), PRESS_NO_ROLE_1) == false, "non-user payments caller should have different access");                
    }

    function test_sort() public setUpCurationStrategy {
        
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

        // call sort
        // TODO : the following tests are off because the tokenIds being sorted should be #1, #2 not #0, #1.
        //      believe the issue with how the database is reconstructing sort data for readAllData call, 
        //      rather than an issue on the write side
        //      **********
        //      **********
        //      **********
        //      **********        

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;

        int96[] memory sortOrders = new int96[](2);
        sortOrders[0] = 1;
        sortOrders[1] = -1;

        targetPressProxy.sort(tokenIds, sortOrders);

        // check that sortOrders being stored in database `idToData` mapping correctly
        (
            address pointerAddress,
            int96 sortValue
        ) = database.idToData(address(targetPressProxy), tokenIds[0]);
        require(sortOrders[0] == sortValue, "sort order incorrect");
        (
            address pointerAddress_2,
            int96 sortValue_2
        ) = database.idToData(address(targetPressProxy), tokenIds[1]);
        require(sortOrders[1] == sortValue_2, "sort order incorrect");   

        // array of structs that look like {bytes storedData, int96 sortOrder}     
        (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        require(tokenData[0].sortOrder == 1, "incorrect sortOrder");
        require(tokenData[1].sortOrder == -1, "incorrect sortOrder");

        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER doesnt have sort access
        vm.expectRevert(abi.encodeWithSignature("No_Sort_Access()"));
        targetPressProxy.sort(tokenIds, sortOrders);
    }
}