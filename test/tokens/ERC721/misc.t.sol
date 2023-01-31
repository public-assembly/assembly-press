// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {PressConfig} from "./utils/PressConfig.sol";

contract ERC721Press_misc is PressConfig {

    function test_initialize() public setUpPressBase {
        // Test contract owner is supplied owner
        assert(erc721Press.owner() == INITIAL_OWNER);
        // Log contract name
        console2.log(erc721Press.name());
        // Log contract symbol
        console2.log(erc721Press.symbol());
    }
}