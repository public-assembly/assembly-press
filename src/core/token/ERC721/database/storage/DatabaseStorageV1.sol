// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IDatabaseEngine } from "../interfaces/IDatabaseEngine.sol";

/**
 @notice Curation storage variables contract.
 */
abstract contract DatabaseStorageV1 is IDatabaseStorage {

    /// @notice Press => id => address (pointer to bytes encoded listing struct) mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank/burned entries (not garbage compacted!)
    mapping(address => mapping(uint256 => address)) public idToData;

    /// @notice Press => config information
    mapping(address => Config) public configInfo;
  
    // Public constants for access roles
    uint16 public constant ANYONE = 0;
    uint16 public constant USER = 1;
    uint16 public constant MANAGER = 2;
    uint16 public constant ADMIN = 3; 

    /// @notice Storage gap
    uint256[49] __gap;
}