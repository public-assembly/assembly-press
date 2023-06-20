// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721PressRenderer {
    function initializeWithData(address targetPress, bytes memory rendererInit) external;
    function getContractURI(address targetPress) external view returns (string memory);    
    function getTokenURI(address targetPress, uint256 tokenId) external view returns (string memory);   
}