// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";
import "sstore2/SSTORE2.sol";
// import "solmate/utils/SSTORE2.sol";

contract MockEncoder {
    // STORAGE
    mapping(uint256 => address) public idToPointer;
    uint256 public counter;
    uint256 constant PACKED_LISTING_STRUCT_LENGTH = 85;

    // TYPES
    struct Listing {
        uint256 chainId;
        uint256 tokenId;
        address listingAddress;
        uint8 hasTokenId;
    }

    // ERRORS
    error Incorrect_Data();

    // FUNCTIONS
    function _validateData(bytes memory data) internal pure {
        Listing memory listing = Listing({
            chainId: BytesLib.toUint256(data, 0),
            tokenId: BytesLib.toUint256(data, 32),
            listingAddress: BytesLib.toAddress(data, 64),
            hasTokenId: BytesLib.toUint8(data, 84)
        });
    }

    function storeData(address storeCaller, bytes calldata data) external {
        // Cache msg.sender -- which is the Press if called correctly
        address sender = msg.sender;

        if (data.length % PACKED_LISTING_STRUCT_LENGTH != 0) {
            revert Incorrect_Data();
        }

        uint256 loops = data.length / PACKED_LISTING_STRUCT_LENGTH;

        for (uint256 i = 0; i < loops; ++i) {
            // Check data is valid
            _validateData(BytesLib.slice(data, (i * PACKED_LISTING_STRUCT_LENGTH), PACKED_LISTING_STRUCT_LENGTH));
            // _validateData(data[(i * PACKED_LISTING_STRUCT_LENGTH):(i*PACKED_LISTING_STRUCT_LENGTH)]);
            // use sstore2 to store bytes segments in bytes array
            idToPointer[counter] =
                SSTORE2.write(BytesLib.slice(data, (i * PACKED_LISTING_STRUCT_LENGTH), PACKED_LISTING_STRUCT_LENGTH));
            // increment press storedCounter after storing data
            ++counter;
        }
    }
}
