// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ICurationLogic } from "../interfaces/ICurationLogic.sol";

/**
 @notice Curation storage variables contract.
 */
abstract contract CurationStorageV1 is ICurationLogic {

    /// @notice address => Listing id => address (pointer to bytes encoded listing struct) mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank entries (not garbage compacted!)
    mapping(address => mapping(uint256 => address)) public idToListing;

    /// @notice Press => config information
    mapping(address => Config) public configInfo;
  
    // Public constants for access roles
    uint16 public constant ANYONE = 0;
    uint16 public constant CURATOR = 1;
    uint16 public constant MANAGER = 2;
    uint16 public constant ADMIN = 3; 

    // Bytes length of encoded listing struct
    uint16 public constant LISTING_SIZE = 160;

    /// @notice Storage gap
    uint256[49] __gap;
}