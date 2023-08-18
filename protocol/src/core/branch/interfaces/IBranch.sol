// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface IBranch {
    /// @notice Deploys and initializes new channel
    function createChannel(bytes memory init) external returns (address);
}
