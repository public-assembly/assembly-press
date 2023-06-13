// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC721Press_GasConfig} from "./utils/ERC721Press_GasConfig.sol";
import {ICurationLogic} from "../../src/token/ERC721/strategies/curation/interfaces/ICurationLogic.sol";
import {CurationLogic} from "../../src/token/ERC721/strategies/curation/logic/CurationLogic.sol";

contract ERC721Press_GasTest is ERC721Press_GasConfig {

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData() public {        
        address curatorPersona_1 = address(0x666);        
        vm.startPrank(curatorPersona_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;      
        // bytes memory encodedListings = abi.encode(listings);
        bytes memory encodedListings = encodeListingArray(listings);
        erc721Press.mintWithData(1, encodedListings);

        console2.log("address of erc721 press: ", address(erc721Press));


        (
            bytes memory data
        ) = CurationLogic(address(erc721Press.getLogic())).idToListing(address(erc721Press), 1);

        console2.log("bytes memory data length :", data.length);
        ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 1); 
        
        
        // getListing(address(erc721Press), 1)

        // (
        //     ICurationLogic.Listing memory x
        //     // uint128 a,
        //     // uint128 b,
        //     // address c,
        //     // int32 d,
        //     // bool e
        // ) = ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 1);          
    }


    // HELPERS 
    function encodeListing(ICurationLogic.Listing memory _listing) public pure returns (bytes memory) {
        return abi.encodePacked(
            _listing.listingAddress,
            _listing.tokenId,
            _listing.sortOrder,
            _listing.chainId,
            _listing.hasTokenId
        );
    }        

    event encodedListingBytes (bytes theBytes, uint256 lengthBytes);

    function encodeListingArray(ICurationLogic.Listing[] memory _listings) public returns (bytes memory) {
        bytes memory encodedListings;
        for (uint i = 0; i < _listings.length; i++) {
            encodedListings = abi.encodePacked(encodedListings, encodeListing(_listings[i]));
            emit encodedListingBytes(encodeListing(_listings[i]), encodeListing(_listings[i]).length);
        }
        return encodedListings;
    }    
}