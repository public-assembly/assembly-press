// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface IRenderer {
    /// @notice Initializes setup data in renderer contract
    function initializeWithData(bytes memory initData) external;
}
