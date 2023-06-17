// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721PressRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory rendererInit) external;
}