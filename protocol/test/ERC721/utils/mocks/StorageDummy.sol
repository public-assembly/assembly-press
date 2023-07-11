// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";
import "sstore2/SSTORE2.sol";

contract StorageDummy {
    
    // ===== TYPES
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: chainId (32) = 32 bytes
     * Second slot: tokenId (32) = 32 bytes    
     * Third slot: listingAddress (20) + hasTokenId (1) = 21 bytes
     */
    struct Listing {
        /// @notice ChainID for curated contract
        uint256 chainId;        
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint256 tokenId;        
        /// @notice Address that is curated
        address listingAddress;
        /// @notice Has token Id ********
        uint8 hasTokenId;
    }        

    // ===== STORAGE STRATEGIES
    // STORAGE STRAT 1
    //      abi.encode(abi.encode(listing.chainId, listing.tokenId, listing.listingAddress, hasTokenId))
    mapping(uint256 => address) public storageMapping_1;
    uint256 public counter_1;    

    // STORAGE STRAT 2
    //      abi.encodePacked(abi.encodePacked(listing.chainId, listing.tokenId, listing.listingAddress, hasTokenId))
    mapping(uint256 => address) public storageMapping_2;
    uint256 public counter_2;
    uint256 constant PACKED_LISTING_STRUCT_LENGTH = 85;

    // STORAGE STRAT 3
    //      abi.encode(abi.encode(Listing))
    mapping(uint256 => address) public storageMapping_3;
    uint256 public counter_3;        

    // STORAGE STRAT 4
    //      abi.encode(Listing)
    mapping(uint256 => address) public storageMapping_4;
    uint256 public counter_4;    

    // ===== FUNCTIONS

    // NO FOR LOOP
    function storeData_Config1(bytes memory data) external {
        // validate data
        Listing memory listing = abi.decode(data, (Listing));
        // store data
        storageMapping_1[counter_1] = SSTORE2.write(data);
        // incremenet counter
        ++counter_1;
    }

    function storeData_Config2(bytes memory data) external {
        // validate data
        Listing memory listing = Listing({
            chainId: BytesLib.toUint256(data, 0),
            tokenId: BytesLib.toUint256(data, 32),
            listingAddress: BytesLib.toAddress(data, 64),
            hasTokenId: BytesLib.toUint8(data, 84)            
        });     
        // store data
        storageMapping_2[counter_2] = SSTORE2.write(data);
        // increment counter
        ++counter_2;
    }    

    function storeData_Config3(bytes memory data) external {
        // validate data
        Listing memory listing = abi.decode(data, (Listing));
        // store data
        storageMapping_3[counter_3] = SSTORE2.write(data);
        // incremenet counter
        ++counter_3;
    }

    // WITH FOR LOOP
    function storeData_Config1_ForLoop(bytes memory data) external {

        (bytes[] memory tokens) = abi.decode(data, (bytes[]));

        for (uint256 i; i < tokens.length; ++i) {
            // validate data
            Listing memory listing = abi.decode(tokens[i], (Listing));
            // store data
            storageMapping_1[counter_1] = SSTORE2.write(tokens[i]);            
            // incremenet counter
            ++counter_1;
        }
    }

    function storeData_Config2_ForLoop(bytes calldata data) external {
        
        // Calculate number of tokens to loop through
        uint256 tokens = data.length / PACKED_LISTING_STRUCT_LENGTH;

        for (uint256 i = 0; i < tokens; ++i) {
            // validate data
            Listing memory listing = Listing({
                chainId: BytesLib.toUint256(data, (0 + (i * PACKED_LISTING_STRUCT_LENGTH))),
                tokenId: BytesLib.toUint256(data, (32 + (i * PACKED_LISTING_STRUCT_LENGTH))),
                listingAddress: BytesLib.toAddress(data, (64 + (i * PACKED_LISTING_STRUCT_LENGTH))),
                hasTokenId: BytesLib.toUint8(data, (84 + (i * PACKED_LISTING_STRUCT_LENGTH)))            
            });   
            // store data
            storageMapping_2[counter_2] = SSTORE2.write(
                data[(i * PACKED_LISTING_STRUCT_LENGTH):((i + 1) * PACKED_LISTING_STRUCT_LENGTH)]            
            );    
            // increment counter
            ++counter_2;            
        }
    }        
}