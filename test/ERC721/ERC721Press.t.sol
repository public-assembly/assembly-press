// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";

import {OpenAccess} from "../../src/token/ERC721/curation/access/OpenAccess.sol";
import {CurationLogic} from "../../src/token/ERC721/curation/logic/CurationLogic.sol";
import {OpenAccess} from "../../src/token/ERC721/curation/access/OpenAccess.sol";
import {ICurationLogic} from "../../src/token/ERC721/curation/interfaces/ICurationLogic.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";

import {ERC721PressFactory} from "../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721Press} from "../../src/token/ERC721/ERC721Press.sol";

import {HybridAccess} from "../../src/token/ERC721/curation/access/HybridAccess.sol";

contract ERC721PressTest is ERC721PressConfig {

    // // mintWithData test doubles as a test for addListing call on CurationLogic 
    // function test_mintWithData_OD() public setUpPressCurationLogic {      
    //     vm.startPrank(INITIAL_OWNER);  
    //     curationLogic.setCurationPaused(address(erc721Press), false);
    //     vm.stopPrank();    
    //     vm.startPrank(CURATOR_1);
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
    //     listings[0].curatedAddress = address(0x111);
    //     listings[0].selectedTokenId = 1;
    //     listings[0].curator = CURATOR_1;
    //     listings[0].curationTargetType = 4; // curationType = NFT Item
    //     listings[0].sortOrder = 1;
    //     listings[0].hasTokenId = true;
    //     listings[0].chainId = 1;
    //     listings[1].curatedAddress = address(0x333);
    //     listings[1].selectedTokenId = 0;
    //     listings[1].curator = CURATOR_1;
    //     listings[1].curationTargetType = 1; // curationType = NFT Contract
    //     listings[1].sortOrder = -1;
    //     listings[1].hasTokenId = false;
    //     listings[1].chainId = 1;        

    //     bytes memory listing1Bytes = abi.encode(
    //         listings[0].curatedAddress,
    //         listings[0].selectedTokenId,
    //         listings[0].curator,
    //         listings[0].sortOrder,
    //         listings[0].curationTargetType,
    //         listings[0].chainId,
    //         listings[0].hasTokenId
    //     );

    //     bytes memory listing2Bytes = abi.encode(
    //         listings[1].curatedAddress,
    //         listings[1].selectedTokenId,
    //         listings[1].curator,
    //         listings[1].sortOrder,
    //         listings[1].curationTargetType,
    //         listings[1].chainId,
    //         listings[1].hasTokenId
    //     );

    //     bytes memory encodedListings = abi.encodePacked(listing1Bytes, listing2Bytes);        

    //     erc721Press.mintWithData(2, encodedListings);

    //     /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
    //     // console2.log(erc721Press.contractURI());
    //     // console2.log(erc721Press.tokenURI(1));

    //     require(ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 2).curator == CURATOR_1, "listing added incorrectly");
    //     require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");        
    //     vm.stopPrank();
    //     // switching personas to test getListingsForCurator function
    //     vm.startPrank(CURATOR_2);
    //     ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
    //     listings_2[0].curatedAddress = address(0x444);
    //     listings_2[0].selectedTokenId = 0;
    //     listings_2[0].curator = CURATOR_2;
    //     listings_2[0].curationTargetType = 1; // curationType = NFT Contract
    //     listings_2[0].sortOrder = 3;
    //     listings_2[0].hasTokenId = false;
    //     listings_2[0].chainId = 4;          
    //     bytes memory encodedListings_2 = abi.encode(listings_2);
    //     erc721Press.mintWithData(1, encodedListings_2);
    //     require(erc721Press.ownerOf(3) == CURATOR_2, "minted incorrectly");
    // }


    function test_initialize() public setUpPressCurationLogic {
        // Test contract owner is supplied owner
        require(erc721Press.owner() == INITIAL_OWNER, "owner incorrect");

        // Test erc721Press has been initialized on curation logic
        require(curationLogic.isInitialized(address(erc721Press)) == true, "not correct");

        require(hybridAccess.curatorGateInfo(address(erc721Press)) == address(mockCurationPass), "not correct");

        require(curationLogic.isPaused(address(erc721Press)) == true, "not correct");

        require(mockCurationPass.balanceOf(CURATOR_1) == 1 && mockCurationPass.balanceOf(CURATOR_2) == 1, "not correct");
    }

    function test_rolesAndGate() public setUpPressCurationLogic {
        require(hybridAccess.getAccessLevel(address(erc721Press), INITIAL_OWNER) == 3, "admin set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == 2, "manager set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), CURATOR_1) == 1, "curation pass set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), address(0x12345)) == 0, "total access control set incorrectly");
        vm.startPrank(INITIAL_OWNER);
        // set up new roles
        HybridAccess.RoleDetails[] memory newRoles = new HybridAccess.RoleDetails[](1);
        newRoles[0].account = FUNDS_RECIPIENT;
        newRoles[0].role = ADMIN_ROLE;

        (uint8 role) = hybridAccess.roleInfo(address(erc721Press), INITIAL_OWNER);
        console2.log("role", role);

        hybridAccess.grantRoles(address(erc721Press), newRoles);
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == 3, "admin set incorrectly");

        address[] memory accountsToRevoke = new address[](1);
        accountsToRevoke[0] = FUNDS_RECIPIENT;
        hybridAccess.revokeRoles(address(erc721Press), accountsToRevoke);
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == NO_ROLE, "admin role not revoked");
        vm.stopPrank();

        address newCuratorGate = address(0x777);

        vm.startPrank(FUNDS_RECIPIENT);
        // expect revert because FUNDS_RECIPIENT is not an admin at this point in the code
        vm.expectRevert();
        hybridAccess.setCuratorGate(address(erc721Press), newCuratorGate);
        vm.stopPrank();
        
        vm.startPrank(INITIAL_OWNER);
        hybridAccess.setCuratorGate(address(erc721Press), newCuratorGate);
        require(hybridAccess.curatorGateInfo(address(erc721Press)) == newCuratorGate, "gate change incorrect");
    }       

    function test_unpause() public setUpPressCurationLogic {
        vm.startPrank(CURATOR_1);
        // expect revert because CURATOR address doesnt have access to adjust pause state
        vm.expectRevert();
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();
        vm.startPrank(INITIAL_OWNER);
        // expect revert because trying to set pause to same state it already is
        vm.expectRevert();
        curationLogic.setCurationPaused(address(erc721Press), true);
        // next call should pass because its being called by an admin and updated pause correctly
        curationLogic.setCurationPaused(address(erc721Press), false);
        require(curationLogic.isPaused(address(erc721Press)) == false, "not correct");
    }

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData() public setUpPressCurationLogic {      
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();    
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);

        /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
        // console2.log(erc721Press.contractURI());
        // console2.log(erc721Press.tokenURI(1));

        require(ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 2).curator == CURATOR_1, "listing added incorrectly");
        require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");        
        vm.stopPrank();
        // switching personas to test getListingsForCurator function
        vm.startPrank(CURATOR_2);
        ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
        listings_2[0].curatedAddress = address(0x444);
        listings_2[0].selectedTokenId = 0;
        listings_2[0].curator = CURATOR_2;
        listings_2[0].curationTargetType = 1; // curationType = NFT Contract
        listings_2[0].sortOrder = 3;
        listings_2[0].hasTokenId = false;
        listings_2[0].chainId = 4;          
        bytes memory encodedListings_2 = abi.encode(listings_2);
        erc721Press.mintWithData(1, encodedListings_2);
        require(erc721Press.ownerOf(3) == CURATOR_2, "minted incorrectly");
    }

    function test_burn() public setUpPressCurationLogic {
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();        
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);
        require(erc721Press.ownerOf(2) == CURATOR_1, "minted incorrectly");        
        erc721Press.burn(2);
        require(erc721Press.balanceOf(CURATOR_1) == 1, "burn not functioning correctly");     
        // should revert since token 2 has been burned
        vm.expectRevert();
        erc721Press.ownerOf(2);
    }

    function test_soulbound() public setUpPressCurationLogic {
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();                
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(1, encodedListings);
        require(erc721Press.ownerOf(1) == CURATOR_1, "minted incorrectly");        
        vm.expectRevert();
        erc721Press.safeTransferFrom(CURATOR_1, address(0x123), 1, new bytes(0));
    }

    // function test_factory() public {
    //     erc721Creator = new ERC721PressCreatorV1(
    //         erc721PressImpl,
    //         curationLogic,
    //         curationRenderer,
    //         address(openAccess)
    //     );

    //     curationContract = ERC721Press(payable(erc721Creator.createCuration(
    //         "MOVEMENT", 
    //         "SYMBOL"
    //     )));

    //     address curatorPersona_1 = address(0x666);        
    //     vm.startPrank(curatorPersona_1);
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
    //     listings[0].curatedAddress = address(0x111);
    //     listings[0].selectedTokenId = 1;
    //     listings[0].curator = curatorPersona_1;
    //     listings[0].curationTargetType = 4; // curationType = NFT Item
    //     listings[0].sortOrder = 1;
    //     listings[0].hasTokenId = true;
    //     listings[0].chainId = 1;
    //     bytes memory encodedListings = abi.encode(listings);
    //     curationContract.mintWithData(1, encodedListings);
    //     require(curationContract.ownerOf(1) == curatorPersona_1, "minted incorrectly");  
    // }

    // function test_curatorEncoding() public {
    //     erc721Creator = new ERC721PressCreatorV1(
    //         erc721PressImpl,
    //         curationLogic,
    //         curationRenderer,
    //         address(openAccess)
    //     );

    //     curationContract = ERC721Press(payable(erc721Creator.createCuration(
    //         "MOVEMENT", 
    //         "SYMBOL"
    //     )));

    //     address curatorPersona_1 = 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170;        
    //     vm.startPrank(curatorPersona_1);        
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
    //     listings[0].curatedAddress = 0x9c05Ae01E80EaBe46023b8847FbcbC4aFb25D959;
    //     listings[0].selectedTokenId = 1;
    //     listings[0].curator = curatorPersona_1;
    //     listings[0].curationTargetType = 4; // curationType = NFT Item
    //     listings[0].sortOrder = 0;
    //     listings[0].hasTokenId = true;
    //     listings[0].chainId = 5;
    //     bytes memory encodedListings = abi.encode(listings);  
    //     curationContract.mintWithData(1, encodedListings);
    //     require(curationContract.ownerOf(1) == curatorPersona_1, "minted incorrectly");          
    // }
}