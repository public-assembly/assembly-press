// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";

/**
 @notice ArtifactRenderer
 @author Max Bochman
 */
contract ArtifactRenderer is IMetadataRenderer {

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

    string contractURI;

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default initializer for collection level data of a specific zora ERC721 drop contract
    /// @notice contractURI must be set to non blank string value 
    /// @param data data to init with
    function initializeWithData(bytes memory rendererInit) external {
        // data format: contractURI
        (
            string memory contractUriInit, 
        ) = abi.decode(data, (string));

        // check if contractURI is being set to empty string
        if (bytes(contractUriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURI = contractUriInit;
    }   

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param newContractURI new string value
    function updateContractURI(string memory newContractURI) external {
        
        // check if contractURI is being set to empty string
        if (bytes(contractUriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        // update contractURI value
        contractURI = newContractURI;
    }

    /// @notice sets up metadata schema for each token
    function initializeTokenMetadata(bytes artifactMetadataInit) external {
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