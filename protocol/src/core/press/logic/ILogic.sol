// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface ILogic {
    /// @notice Initializes setup data in logic contract
    function initializeWithData(bytes memory initData) external;
    function collectRequest(address sender, address recipient, uint256 tokenId, uint256 quantity)
        external
        returns (bool, uint256);
}
