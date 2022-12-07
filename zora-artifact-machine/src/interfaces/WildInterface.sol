// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface WildInterface {
    function updateArtifact(address, uint256, address, string memory) external returns (bool);
    function updateContractURI(address, string memory) external;
}