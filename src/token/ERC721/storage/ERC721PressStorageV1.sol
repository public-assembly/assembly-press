// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

contract ERC721PressStorageV1 {
    /// @notice Configuration for Press contract storage
    IERC721Press.Configuration public config;      

    /// @notice Storage for logic impl
    IERC721PressLogic internal _logicImpl;

    /// @notice Storage for renderer
    IERC721PressRenderer internal _rendererImpl;     

    /// @notice Storage for isSoulbound bool
    bool internal _isSoulbound;
}