// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155TokenRenderer {
    function uri(uint256 tokenId) external view returns (string memory);
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external;    
}