// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721Press} from "../interfaces/IERC721Press.sol";

contract ERC721PressStorageV1 {
    /// @notice Configuration for Press contract storage
    IERC721Press.Configuration public config;      
}