
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title ICuratorInfo
/// @notice This is a modiified version of an earlier impl authored by Iain Nash
interface ICurationInfo {
    function name() external view returns (string memory);
    function owner() external view returns (address);
}