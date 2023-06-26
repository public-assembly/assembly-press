// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IERC721PressDatabase } from "../../interfaces/IERC721PressDatabase.sol";

/**
 @notice Database storage variables contract
 */
abstract contract ERC721PressDatabaseStorageV1 is IERC721PressDatabase {

    /// @notice Press => ID => {pointer, sortOrder} 
    ///     pointer: sstore2 address of arbitrary bytes data, 
    ///     sortOrder: optional z-index style sorting mechanism for IDs    
    ///     first ID stored per press will be `1`
    /// @dev Can contain blank/burned entries (not garbage compacted)
    /// @dev see IERC721PressDatbase for details on TokenData struct
    mapping(address => mapping(uint256 => TokenData)) public idToData;

    /// @notice Press => Settings information
    /// @dev see IERC721PressDatbase for details on Settings struct
    mapping(address => Settings) public settingsInfo;

    /// @dev Factory address => isOfficial bool
    mapping(address => bool) internal _officialFactories;    
}