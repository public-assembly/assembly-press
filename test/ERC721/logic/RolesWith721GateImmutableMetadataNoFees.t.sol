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

contract RolesWith721GateImmutableMetadataNoFeesTest is ERC721PressConfig {

    function test_initialize() public setUpCurationStrategy {
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address pressRenderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));        
        (
            address erc721Gate,
            uint80 frozenAt,
            bool isPaused,
            bool isTokenDataImmutable            
        ) = RolesWith721GateImmutableMetadataNoFees(logic).settingsInfo(address(targetPressProxy));        
        require(erc721Gate == address(mockAccessPass), "erc721Gate initialized incorrectly");
        require(frozenAt == 0 , "frozenAt should be 0 post initialization");
        require(isPaused == false , "isPaused initialized incorrectly");        
        require(isTokenDataImmutable == true , "isTokenDataImmutable initialized incorrectly");        

        // test all roles on initialization
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == ADMIN_ROLE);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_MANAGER) == MANAGER_ROLE);
        // PRESS_USER should have NO_ROLE because its access level is determined by balance of access pass, not targeted role assignment
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_USER) == NO_ROLE);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_NO_ROLE_1) == NO_ROLE);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_NO_ROLE_2) == NO_ROLE);            
    }

    function test_initializeGuard() public setUpCurationStrategy {
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address pressRenderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));      

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // set up mock data + access roles for init test        
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory mockRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](0);
        // mockInitData: (erc721Gate, isPaused, isTokenDataImmutable, roles)
        bytes memory mockInitData = abi.encode(address(0x123), false, true, mockRoles);        

        // should revert to enforce check that initializeWithData can only called by the database contract for a given Press
        vm.expectRevert(abi.encodeWithSignature("UnauthorizedInitializer()"));
        // revert if trying to call initialize function from not the database
        RolesWith721GateImmutableMetadataNoFees(pressLogic).initializeWithData(address(targetPressProxy), mockInitData);    
        vm.stopPrank();

        vm.startPrank(address(targetPressProxy.getDatabase()));
        // shouldnt revert because Database is calling initialize function
        RolesWith721GateImmutableMetadataNoFees(pressLogic).initializeWithData(address(targetPressProxy), mockInitData);         
    }        

    function test_getMintPrice() public setUpCurationStrategy {
        (
            uint256 storedcounter,
            address logic,
            uint8 initialized, 
            address renderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));        
        (uint256 logicSpecific_UniversalMintPrice) = RolesWith721GateImmutableMetadataNoFees(logic).getMintPrice(address(targetPressProxy), PRESS_USER, 1);     
        require(logicSpecific_UniversalMintPrice == 0, "mint price incorrect");      
    }    

    function test_GrantAndRevokeRoles() public setUpCurationStrategy {        
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address renderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));        
        vm.startPrank(PRESS_MANAGER);
        // expect revert because manager doesnt have access to set pause status on this contract
        vm.expectRevert(abi.encodeWithSignature("RequiresAdmin()"));
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), false);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_MANAGER) == MANAGER_ROLE, "incorrect role assigned");
        vm.stopPrank();

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // construct role arrays
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory newRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](1);
        newRoles[0].account = PRESS_MANAGER;
        newRoles[0].role = ADMIN_ROLE;
        RolesWith721GateImmutableMetadataNoFees(pressLogic).assignRoles(address(targetPressProxy), newRoles);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_MANAGER) == ADMIN_ROLE, "incorrect role assigned");        
        vm.stopPrank();

        vm.startPrank(PRESS_MANAGER);
        // test that press_manager now has admin role to call setIsPaused
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), false);    
        // construct revoke array    
        address[] memory accountsToRevoke = new address[](1);
        accountsToRevoke[0] = PRESS_ADMIN_AND_OWNER;      
        RolesWith721GateImmutableMetadataNoFees(pressLogic).revokeRoles(address(targetPressProxy), accountsToRevoke);
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == NO_ROLE, "revoke did not work");                
        
        vm.stopPrank();
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // expect revert because press_admin_and_owner doesnt have admin role anymore
        vm.expectRevert(abi.encodeWithSignature("RequiresAdmin()"));
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), false);            
    }  

    function test_isPaused() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address renderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), true);
        vm.stopPrank();
        vm.startPrank(PRESS_MANAGER);
        // expect revert because manager doesnt have access to set pause status on this contract
        vm.expectRevert(abi.encodeWithSignature("RequiresAdmin()"));
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), false);
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        // expect revert because minting is now paused on this press for accounts with role < MANAGER due to pressLogic contract
        vm.expectRevert(abi.encodeWithSignature("DatabasePaused()"));
        targetPressProxy.mintWithData(1, encodedListings);
        vm.stopPrank();
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setIsPaused(address(targetPressProxy), false);
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // shouldnt revert because isPaused has been set to false
        targetPressProxy.mintWithData(1, encodedListings);
    }                 

    function test_frozenAt() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address renderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));
        (
            address erc721Gate,
            uint80 frozenAt,
            bool isPaused,
            bool isTokenDataImmutable            
        ) = RolesWith721GateImmutableMetadataNoFees(pressLogic).settingsInfo(address(targetPressProxy));   
        require(frozenAt == 0 , "frozenAt should be 0 post initialization");       
        // set up data for mint
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        // mint call should go through because not frozen
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 1, "mint not functioning correctly");                 
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setFrozenAt(address(targetPressProxy), (uint80(block.timestamp)));
        vm.warp(block.timestamp + 1);       
        // follow up mint call should revert even for admin since database is frozenAt < block.timestamp
        vm.expectRevert(abi.encodeWithSignature("DatabaseFrozen()"));
        targetPressProxy.mintWithData(1, encodedListings);
    }      

    function test_erc721Gate() public setUpCurationStrategy {
        vm.startPrank(PRESS_USER);
        (
            uint256 storedcounter,
            address pressLogic,
            uint8 initialized, 
            address renderer
        ) = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));
        (
            address erc721Gate,
            uint80 frozenAt,
            bool isPaused,
            bool isTokenDataImmutable            
        ) = RolesWith721GateImmutableMetadataNoFees(pressLogic).settingsInfo(address(targetPressProxy));   

        require(mockAccessPass.balanceOf(PRESS_USER) == 1, "mint not functioning correctly");
        // check that PRESS_USER doesnt have an admin/manager role assigned
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).roleInfo(address(targetPressProxy), PRESS_USER) == NO_ROLE, "incorrect role assigned");         
        // check that PRESS_USER still has USER access due to having balance 1 of erc721Gate
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).getAccessLevel(address(targetPressProxy), PRESS_USER) == USER, "incorrect access level");         
        // set up data for mint
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        // mint call should go through because PRESS_USER has USER access
        targetPressProxy.mintWithData(1, encodedListings);
        mockAccessPass.safeTransferFrom(PRESS_USER, address(0x123), 1, new bytes(0));
        require(mockAccessPass.balanceOf(PRESS_USER) == 0, "transfer not functioning correctly");
        // confirm that PRESS_USER now has NO_ROLE access after transfering out erc721Gate token
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).getAccessLevel(address(targetPressProxy), PRESS_USER) == NO_ROLE, "incorrect access level");         
        // expect revert because PRESS_USER doesn't have USER access anymore
        vm.expectRevert(abi.encodeWithSignature("No_Mint_Access()"));
        targetPressProxy.mintWithData(1, encodedListings);

        // deploy new access pass
        MockERC721 mockAccessPass_2 = new MockERC721();
        mockAccessPass_2.mint(PRESS_USER);
        require(mockAccessPass_2.balanceOf(PRESS_USER) == 1, "mint not functioning correctly");
        vm.stopPrank();

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        RolesWith721GateImmutableMetadataNoFees(pressLogic).setErc721Gate(address(targetPressProxy), address(mockAccessPass_2));
        (
            address erc721Gate_again,
            uint80 frozenAt_again,
            bool isPaused_again,
            bool isTokenDataImmutable_again            
        ) = RolesWith721GateImmutableMetadataNoFees(pressLogic).settingsInfo(address(targetPressProxy));     
        require(erc721Gate_again == address(mockAccessPass_2), "setErc721Gate not working correctly");    
        vm.stopPrank();

        vm.startPrank(PRESS_USER);
        // PRESS_USER should have USER access again because has a balance of 1 of the new erc721Gate
        require(RolesWith721GateImmutableMetadataNoFees(pressLogic).getAccessLevel(address(targetPressProxy), PRESS_USER) == USER, "incorrect access level");         
        // mint call should NOT revert because PRESS+USER has access
        targetPressProxy.mintWithData(1, encodedListings); 
    }        
}