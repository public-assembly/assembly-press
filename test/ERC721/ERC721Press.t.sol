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
        require(pressSettings.transferable == false, "funds recipient set incorrectly");

        // (RolesWith721GateImmutableMetadataNoFees[] memory roleDetails) = logic.roleInfo(address(targetPressProxy));
        require(logic.roleInfo(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == ADMIN_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_MANAGER) == MANAGER_ROLE);
        // PRESS_USER should have NO_ROLE because its access level is determined by balance of access pass, not targeted role assignment
        require(logic.roleInfo(address(targetPressProxy), PRESS_USER) == NO_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_NO_ROLE_1) == NO_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_NO_ROLE_2) == NO_ROLE);
    
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

    /* TODO
    * 1. add erc721Press setSettings teset
    * 2. add checks that msg value is actually getting transferred correctly to recipient
    * 3. add mintBurnSort tests
    * 4. add tests for upgrades + transfers
    * 5. do factory impl + tests
    * 6. deploys ???
    * 7. first pass diagrams
    */      
}