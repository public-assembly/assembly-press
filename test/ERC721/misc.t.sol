// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";

contract ERC721Press_misc is ERC721PressConfig {

    function test_initialize() public setUpERC721PressBase {
        // Test contract owner is supplied owner
        assert(erc721Press.owner() == INITIAL_OWNER);
        // Log contract name
        console2.log(erc721Press.name());
        // Log contract symbol
        console2.log(erc721Press.symbol());
    }
}