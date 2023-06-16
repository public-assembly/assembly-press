// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

contract ERC721PressStorageV1 {

    // ||||||||||||||||||||||||||||||||
    // ||| PUBLIC STORAGE |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Max royalty BPS
    uint16 constant public MAX_ROYALTY_BPS = 50_00;

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL STORAGE |||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Storage for database impl
    IERC721PressDatabase internal _database;

    /// @notice Settings for Press contract
    IERC721Press.Settings internal _settings;      

    /// @dev Recommended max mint batch size for ERC721A
    uint256 constant internal _MAX_MINT_BATCH_SIZE = 8;
}

