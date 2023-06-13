// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC721Press_GasConfig} from "./utils/ERC721Press_GasConfig.sol";
import {ICurationLogic} from "../../src/token/ERC721/strategies/curation/interfaces/ICurationLogic.sol";

contract ERC721Press_GasTest is ERC721Press_GasConfig {

    // mintWithData test doubles as a test for making sure data is being encoded/decoded correctly
    //      data passing is being tested with curation logic in this test
    function test_mintWithData() public {        
        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);         
        listings[0].chainId = 1;      
        listings[0].tokenId = 1;
        listings[0].listingAddress = address(0x111);
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        bytes memory encodedListings = encodeListingArray(listings);
        erc721Press.mintWithData(1, encodedListings);              
    }
}