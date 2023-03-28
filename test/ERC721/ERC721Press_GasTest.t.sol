// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC721Press_GasConfig} from "./utils/ERC721Press_GasConfig.sol";
import {ICurationLogic} from "../../src/token/ERC721/curation/interfaces/ICurationLogic.sol";

contract ERC721Press_GasTest is ERC721Press_GasConfig {

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData() public returns (bytes memory) {        
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

        // // test listing for etherscan
        // ICurationLogic.Listing[] memory test_Listing = new ICurationLogic.Listing[](1);        
        // test_Listing[0].curatedAddress = address(0x111);
        // test_Listing[0].selectedTokenId = 1;
        // test_Listing[0].curator = // input your address here;
        // test_Listing[0].curationTargetType = 4; // curationType = NFT Item
        // test_Listing[0].sortOrder = 1;
        // test_Listing[0].hasTokenId = true;
        // test_Listing[0].chainId = 1;              
        // bytes memory test_Encode = abi.encode(test_Listing);
        // return test_Encode;
    }
}