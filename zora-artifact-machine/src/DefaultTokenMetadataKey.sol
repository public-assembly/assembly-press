// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ITokenMetadataKey} from "./interfaces/ITokenMetadataKey.sol";

/** 
 * @title DefaultTokenMetadataKey
 * @dev 
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract DefaultTokenMetadataKey is ITokenMetadataKey {

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    error Blank_Metadata();

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTION ||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice decodeTokenURI
    /// @dev reverts if token does not exist
    /// @return tokenURI uri for given token of collection address (if set)
    function decodeTokenURI(bytes memory artifactMetadata)
        external
        view
        override
        returns (string memory)
    {
        // data format: tokenUri
        (string memory tokenUri) = abi.decode(data, (string));

        return tokenUri;
    }
}