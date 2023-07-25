// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155PressRenderer {
    // Initialize function
    /// @notice initializes renderer with arbitrary data
    function initializeWithData(address targetPress, bytes memory initData) external;
    function getContractURI(address targetPress) external view returns (string memory);
    function getTokenURI(address targetPress, uint256 tokenId) external view returns (string memory);
}
