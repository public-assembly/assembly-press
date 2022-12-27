// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";

/**
 @notice ArtifactoryRenderer
 @author Max Bochman
 */
contract ArtifactoryStorageV1 is IMetadataRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Shared listing struct for both artifactDecoder address + artifactMetadata 
    struct ArtifactDetails {
        address artifactDecoder;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Press -> tokenId -> {artifactDecoder, artifactMetadata}
    mapping(address => mapping(uint256 => address)) public artifactInfo;            

    function initializeWithData(bytes metadataInit) {
        // data format: artifactDetails[]
        (ArtifactDetails[] artifactDetails) = abi.decode(data, (ArtifactDetails[]))

        // calculate number of artifacts to mint
        uint256 numArtifacts = artifactDetails.length;        

        // call admintMint function on target ZORA contract and store last tokenId minted
        uint256 lastTokenMinted = IPress(msg.sender).totalMinted()

        // for length of numArtifacts array, emit CreateArtifact event
        for (uint256 i = 0; i < numArtifacts; i++) {            

            // get current tokenId to process
            uint256 tokenId = lastTokenMinted - (numArtifacts - (i + 1));                        

            // check if artifactRenderer is zero address
            if (artifactDetails[i].artifactRenderer == address(0)){
                revert Cannot_SetToZeroAddress();
            }

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            address dataContract = BytecodeStorage.writeToBytecode(abi.encode(artifactDetails[i]));

            artifactInfo[msg.sender][tokenId] = dataContract;           
        }
    }


}