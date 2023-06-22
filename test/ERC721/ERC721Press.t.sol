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

        // testing database storage
        (
            uint256 storedCounter,
            address pressLogic,
            uint8 initialized,
            address pressRenderer
        ) = database.settingsInfo(address(targetPressProxy));
        require(storedCounter == 0, "stored counter should be zero since no mints have occurred");
        require(pressLogic == address(logic), "press logic initialized in database incorrectly");
        require(initialized == 1, "initialized should equal 1 post initialization");
        require(pressRenderer == address(renderer), "press renderer initialized in database incorrectly");

        // (RolesWith721GateImmutableMetadataNoFees[] memory roleDetails) = logic.roleInfo(address(targetPressProxy));
        require(logic.roleInfo(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == ADMIN_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_MANAGER) == MANAGER_ROLE);
        // PRESS_USER should have NO_ROLE because its access level is determined by balance of access pass, not targeted role assignment
        require(logic.roleInfo(address(targetPressProxy), PRESS_USER) == NO_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_NO_ROLE_1) == NO_ROLE);
        require(logic.roleInfo(address(targetPressProxy), PRESS_NO_ROLE_2) == NO_ROLE);

        // testing renderer storage
        require(keccak256(bytes(renderer.contractUriImageInfo(address(targetPressProxy)))) == keccak256(bytes("ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH")), "contract uri image path initialized incorrectly");

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

        // check to see if supportsInterface work
        require(targetPressProxy.supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support");
        require(targetPressProxy.supportsInterface(type(IERC5192).interfaceId) == true, "doesn't support");        
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
        (IERC721PressDatabase.TokenDataRetrieved[] memory tokenData) = database.readAllData(address(targetPressProxy));
        require(keccak256(tokenData[0].storedData) == keccak256(abi.encode(listings[0].chainId, listings[0].tokenId, listings[0].listingAddress, listings[0].hasTokenId)), "token #1 data not stored properly");
        require(keccak256(tokenData[1].storedData) == keccak256(abi.encode(listings[1].chainId, listings[1].tokenId, listings[1].listingAddress, listings[1].hasTokenId)), "token #2 data not stored properly");
        // {"name": "Curation Receipt #1","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000333\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"chainId": "1","contract": "0x0000000000000000000000000000000000012345","hasTokenId": "true","tokenId": "3","sortOrder": "0","curator": "0x0000000000000000000000000000000000000333"}}        
        require(
            keccak256(bytes(targetPressProxy.tokenURI(1))) == keccak256(bytes("data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzEiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMzMzXG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY2hhaW5JZCI6ICIxIiwiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDEyMzQ1IiwiaGFzVG9rZW5JZCI6ICJ0cnVlIiwidG9rZW5JZCI6ICIzIiwic29ydE9yZGVyIjogIjAiLCJjdXJhdG9yIjogIjB4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDMzMyJ9fQ==")),
            "token #1 tokenURI not built correctly"
        );        
        // {"name": "Curation Receipt #2","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000333\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"chainId": "7777777","contract": "0x0000000000000000000000000000000000054321","hasTokenId": "false","tokenId": "0","sortOrder": "0","curator": "0x0000000000000000000000000000000000000333"}}
        require(
            keccak256(bytes(targetPressProxy.tokenURI(2))) == keccak256(bytes("data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzIiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMzMzXG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY2hhaW5JZCI6ICI3Nzc3Nzc3IiwiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDU0MzIxIiwiaGFzVG9rZW5JZCI6ICJmYWxzZSIsInRva2VuSWQiOiAiMCIsInNvcnRPcmRlciI6ICIwIiwiY3VyYXRvciI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAzMzMifX0=")),
            "token #2 tokenURI not built correctly"
        );
    }    

    /* TODO
    *
    1. finish Role tests. granting, revoking, confirming access on each press function. frozenAt
    2. testing metadata update functions (contract + token level)
    3. finish other press things like upgrades/transfers
    4. do all the factory stuff
    *
    */      
}