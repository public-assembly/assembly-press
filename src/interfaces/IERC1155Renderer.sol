// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155Renderer {
    function uri(uint256 tokenId) external view returns (string memory);
    function initializeWithData(bytes memory rendererInit) external;    
}