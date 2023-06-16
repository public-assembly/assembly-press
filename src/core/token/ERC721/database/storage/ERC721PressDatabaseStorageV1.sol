// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721PressDatabase } from "../../interfaces/IERC721PressDatabase.sol";

/**
 @notice Database storage variables contract.
 */
abstract contract DatabaseStorageV1 is IERC721PressDatabase {

    /// @notice Press => id => address (pointer to bytes encoded listing struct) mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank/burned entries (not garbage compacted!)
    mapping(address => mapping(uint256 => address)) public idToData;

    /// @notice Press => Settings information
    mapping(address => Settings) public settingsInfo;
  
    // Public constants for access roles
    uint16 public constant ANYONE = 0;
    uint16 public constant USER = 1;
    uint16 public constant MANAGER = 2;
    uint16 public constant ADMIN = 3; 

    /// @notice Storage gap
    uint256[49] __gap;
}