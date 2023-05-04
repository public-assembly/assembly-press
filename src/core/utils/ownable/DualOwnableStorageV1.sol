// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract DualOwnableStorageV1 {
    /// @dev The address of the owner
    address internal _owner;

    /// @dev The address of the pending Owner
    address internal _pendingOwner;       

    /// @dev The address of the secondary owner
    address internal _secondaryOwner;

    /// @dev storage gap
    uint256[50] private __gap;
}