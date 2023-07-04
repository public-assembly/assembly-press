// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";
import "sstore2/SSTORE2.sol";
import {MockEncoder} from "./utils/mocks/MockEncoder.sol";
import {StorageDummy} from "./utils/mocks/StorageDummy.sol";

contract StorageTests is Test {    

    // `storeData_Config1` gas used = 104,597
    function test_storeConfig1() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 1
        StorageDummy.Listing memory listing = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });
        bytes memory encodedListing = abi.encode(
            listing.chainId,
            listing.tokenId,
            listing.listingAddress,
            listing.hasTokenId
        );
        // call store
        storageDummy.storeData_Config1(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_1() == 1, "storage not correct");
    }

    // `storeData_Config1_ForLoop` gas used = 106,101
    function test_forLoop_storeConfig1() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 1
        StorageDummy.Listing[] memory listings = new StorageDummy.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 2;
        listings[0].listingAddress = address(0x123);
        listings[0].hasTokenId = 1;
        bytes memory encodedListing = encodeListingArray(listings);
        // call store
        storageDummy.storeData_Config1_ForLoop(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_1() == 1, "storage not correct");
    }    

    // `storeData_Config1_ForLoop` - 2 listings - gas used = 189,153
    function test_forLoop_multipleListings_storeConfig1() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 1
        StorageDummy.Listing[] memory listings = new StorageDummy.Listing[](2);
        listings[0].chainId = 1;
        listings[0].tokenId = 2;
        listings[0].listingAddress = address(0x123);
        listings[0].hasTokenId = 1;
        listings[1].chainId = 1;
        listings[1].tokenId = 2;
        listings[1].listingAddress = address(0x123);
        listings[1].hasTokenId = 1;        
        bytes memory encodedListing = encodeListingArray(listings);
        // call store
        storageDummy.storeData_Config1_ForLoop(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_1() == 2, "storage not correct");
    }    

    // `storeData_Config2` gas used = 96,114
    function test_storeConfig2() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 2
        StorageDummy.Listing memory listing = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });
        bytes memory encodedListing = abi.encodePacked(
            listing.chainId,
            listing.tokenId,
            listing.listingAddress,
            listing.hasTokenId
        );
        // call store
        storageDummy.storeData_Config2(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_2() == 1, "storage not correct");
    }    

    // `storeData_Config2_ForLoop` gas used = 98,069
    function test_forLoop_storeConfig2() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 2
        StorageDummy.Listing memory listing_1 = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });  
        bytes memory encodedListing = abi.encodePacked(
            listing_1.chainId,
            listing_1.tokenId,
            listing_1.listingAddress,
            listing_1.hasTokenId           
        );
        // call store
        storageDummy.storeData_Config2_ForLoop(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_2() == 1, "storage not correct");
    }        

    // `storeData_Config2_ForLoop` - 2 listings - gas used = 173,838
    function test_forLoop_multipleListings_storeConfig2() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 2
        StorageDummy.Listing memory listing_1 = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });
        StorageDummy.Listing memory listing_2 = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });        
        bytes memory encodedListing = abi.encodePacked(
            listing_1.chainId,
            listing_1.tokenId,
            listing_1.listingAddress,
            listing_1.hasTokenId,
            listing_2.chainId,
            listing_2.tokenId,
            listing_2.listingAddress,
            listing_2.hasTokenId                
        );
        // call store
        storageDummy.storeData_Config2_ForLoop(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_2() == 2, "storage not correct");
    }         

    // `storeData_Config3` gas used = 104,616
    function test_storeConfig3() public {
        // deploy storage dummy
        StorageDummy storageDummy = new StorageDummy();
        // prep data for storage config 3
        StorageDummy.Listing memory listing = StorageDummy.Listing({
            chainId: 1,
            tokenId: 2,
            listingAddress: address(0x123),
            hasTokenId: 1 // 0 = false. 1 = true
        });
        bytes memory encodedListing = abi.encode(listing);
        // call store
        storageDummy.storeData_Config3(encodedListing);
        // uint256 currentCounter = storage
        require(storageDummy.counter_3() == 1, "storage not correct");
    }    

    // ===== LISTING ENCODING HELPERS
    function encodeListing(StorageDummy.Listing memory _listing) public pure returns (bytes memory) {
        return abi.encode(
            _listing.chainId,
            _listing.tokenId,
            _listing.listingAddress,
            _listing.hasTokenId
        );
    }     

    function encodeListingArray(StorageDummy.Listing[] memory _listings) public returns (bytes memory) {
        bytes[] memory encodedListings = new bytes[](_listings.length);
        for (uint i = 0; i < _listings.length; i++) {
            encodedListings[i] = encodeListing(_listings[i]);
        }
        return abi.encode(encodedListings);
    }        

    /* OLD BUT SAVING FOR NOW */
    /************************ */
    /************************ */
    /************************ */
    /************************ */


    // function test_store() public {

    //     MockEncoder.Listing memory listing = MockEncoder.Listing({
    //         chainId: 1,
    //         tokenId: 2,
    //         listingAddress: 0x806164c929Ad3A6f4bd70c2370b3Ef36c64dEaa8,
    //         hasTokenId: 1
    //     });

    //     bytes memory packedListing = abi.encodePacked(
    //         listing.chainId,
    //         listing.tokenId,
    //         listing.listingAddress,
    //         listing.hasTokenId
    //     );

    //     address anyAddress = address(0x123);

    //     MockEncoder mockEncoder = new MockEncoder();

    //     vm.startPrank(address(0x123));

    //     mockEncoder.storeData(address(0x123), packedListing);
        
    //     // require(reconstructedListing.chainId == listing.chainId, "chainId encoding didnt work");
    //     // require(reconstructedListing.tokenId == listing.tokenId, "tokenIdencoding didnt work");        
    //     // require(reconstructedListing.listingAddress == listing.listingAddress, "listingAddress encoding didnt work");       
    //     // require(reconstructedListing.hasTokenId == listing.hasTokenId, "decodedHasTokenId encoding didnt work");  
    // }    
}