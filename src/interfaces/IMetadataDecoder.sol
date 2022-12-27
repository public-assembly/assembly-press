// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IMetadataDecoder {
    function metadataDecoder(bytes memory artifactMetadata) external pure returns (string memory);
}