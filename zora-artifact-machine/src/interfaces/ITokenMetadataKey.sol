// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenMetadataKey {
    function decodeTokenURI(bytes memory artifactMetadata) external returns (string memory);
}