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
        console2.log("length of data passed into mintWithData", encodedListings.length);
        erc721Press.mintWithData(1, encodedListings);              
    }
}

// old: 
// 0x00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001
// 0000000000000000000000000000000000000000000000000000000000000111000000000000000000000000000000000000000000000000000000000000000100000
// 0000000000000000000000000000000000000000000000000000000066600000000000000000000000000000000000000000000000000000000000000010000000000000000000
// 000000000000000000000000000000000000000000001
// 00000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000001

// new:
// 0x0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000
// 1000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a00000
// 00000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000
// 000000000000000000000000000000000000000000
// 11100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001