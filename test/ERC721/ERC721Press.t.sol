// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";
import {DefaultLogic} from "../../src/token/ERC721/logic/DefaultLogic.sol";
import {MockRenderer} from "./mocks/MockRenderer.sol";

import {OpenAccess} from "../../src/token/ERC721/Curation/OpenAccess.sol";
import {CurationLogic} from "../../src/token/ERC721/Curation/CurationLogic.sol";
import {OpenAccess} from "../../src/token/ERC721/Curation/OpenAccess.sol";
import {ICurationLogic} from "../../src/token/ERC721/Curation/ICurationLogic.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";

import {ERC721PressCreatorV1} from "../../src/token/ERC721/ERC721PressCreatorV1.sol";
import {ERC721Press} from "../../src/token/ERC721/ERC721Press.sol";

contract ERC721PressTest is ERC721PressConfig {

    function test_initialize() public setUpERC721PressBase {
        // Test contract owner is supplied owner
        require(erc721Press.owner() == INITIAL_OWNER, "owner incorrect");
    }

    function test_curationLogicSetup() public setUpPressCurationLogic {
        vm.prank(address(ADMIN));
        require(curationLogic.isInitialized(address(erc721Press)) == true, "not correct");
    }    

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData() public setUpPressCurationLogic {        
        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = curatorPersona_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = curatorPersona_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);

        /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
        // console2.log(erc721Press.contractURI());
        // console2.log(erc721Press.tokenURI(1));

        require(ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 2).curator == curatorPersona_1, "listing added incorrectly");
        require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");        
        vm.stopPrank();
        // switching personas to test getListingsForCurator function
        address curatorPersona_2 = address(0x777);
        vm.startPrank(curatorPersona_2);
        ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
        listings_2[0].curatedAddress = address(0x444);
        listings_2[0].selectedTokenId = 0;
        listings_2[0].curator = curatorPersona_2;
        listings_2[0].curationTargetType = 1; // curationType = NFT Contract
        listings_2[0].sortOrder = 3;
        listings_2[0].hasTokenId = false;
        listings_2[0].chainId = 4;          
        bytes memory encodedListings_2 = abi.encode(listings_2);
        erc721Press.mintWithData(1, encodedListings_2);
        require(erc721Press.ownerOf(3) == curatorPersona_2, "minted incorrectly");
    }

    function test_burn() public setUpPressCurationLogic {
        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = curatorPersona_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = curatorPersona_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);
        require(erc721Press.ownerOf(2) == curatorPersona_1, "minted incorrectly");        
        erc721Press.burn(2);
        require(erc721Press.balanceOf(curatorPersona_1) == 1, "burn not functioning correctly");     
        // should revert since token 2 has been burned
        vm.expectRevert();
        erc721Press.ownerOf(2);
    }

    function test_soulbound() public setUpPressCurationLogic {
        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = curatorPersona_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(1, encodedListings);
        require(erc721Press.ownerOf(1) == curatorPersona_1, "minted incorrectly");        
        vm.expectRevert();
        erc721Press.safeTransferFrom(curatorPersona_1, address(0x123), 1, new bytes(0));
    }

    function test_factory() public {
        erc721Creator = new ERC721PressCreatorV1(
            erc721PressImpl,
            curationLogic,
            curationRenderer,
            address(openAccess)
        );

        curationContract = ERC721Press(payable(erc721Creator.createCuration(
            "MOVEMENT", 
            "SYMBOL"
        )));

        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = curatorPersona_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        bytes memory encodedListings = abi.encode(listings);
        curationContract.mintWithData(1, encodedListings);
        require(curationContract.ownerOf(1) == curatorPersona_1, "minted incorrectly");  
    }
}