// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IArtifactMachineMetadataRenderer {
    function updateArtifact(address, uint256, string memory) external returns (bool);
    function updateContractURI(address, string memory) external;
}