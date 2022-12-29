// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ITokenDecoder} from "../interfaces/ITokenDecoder.sol";

/** 
 * @title ArtifactDecoder
 * @notice Simple bytes => string decoder usable by all tokens that 
 *      init address of this contract as their renderer
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract ArtifactDecoder is ITokenDecoder {

    /// @notice decodeTokenURI
    /// @dev returns blank if token not initialized
    /// @return tokenURI uri for given token of collection address (if set)
    function decodeTokenURI(bytes memory artifactMetadata)
        external
        pure
        returns (string memory)
    {
        // data format: tokenURI
        (string memory tokenURI) = abi.decode(artifactMetadata, (string));        

        return tokenURI;
    }    
}