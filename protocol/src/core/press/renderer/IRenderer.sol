// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface IRenderer {
    /// @notice Initializes setup data in renderer contract
    function initializeWithData(bytes memory initData) external;

    // @notice Decocdes uri according to underlying data + instructions
    function decodeUri(bytes calldata data) external returns (string memory);


}
