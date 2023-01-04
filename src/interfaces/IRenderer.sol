// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory rendererInit) external;
    function initializeTokenMetadata(bytes memory tokenInit) external ;    
}