
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title IDatabaseInfo
interface IDatabaseInfo {
    function name() external view returns (string memory);
    function owner() external view returns (address);
}