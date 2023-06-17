// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IERC721PressDatabase } from "../../interfaces/IERC721PressDatabase.sol";

/**
 @notice Database storage variables contract.
 */
abstract contract ERC721PressDatabaseStorageV1 is IERC721PressDatabase {

    /// @notice Press => ID => {pointer, sortOrder} 
    ///     pointer: sstore2 address of arbitrary bytes data, 
    ///     sortOrder: optional z-index style sorting mechanism for IDs    
    ///     IDs are 0 => upwards
    /// @dev Can contain blank/burned entries (not garbage compacted!)
    mapping(address => mapping(uint256 => TokenData)) public idToData;

    /// @notice Press => Settings information
    mapping(address => Settings) public settingsInfo;

    /// @notice Storage gap
    uint256[49] __gap;
}