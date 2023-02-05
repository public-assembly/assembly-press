// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";
import {DefaultLogic} from "../../src/token/ERC721/logic/DefaultLogic.sol";
import {MockRenderer} from "./mocks/MockRenderer.sol";

import {OpenAccess} from "../../src/token/ERC721/Curation/OpenAccess.sol";
import {CurationLogic} from "../../src/token/ERC721/Curation/CurationLogic.sol";
import {OpenAccess} from "../../src/token/ERC721/Curation/OpenAccess.sol";

contract ERC721PressTest is ERC721PressConfig {

    function test_initialize() public setUpERC721PressBase {
        // Test contract owner is supplied owner
        assert(erc721Press.owner() == INITIAL_OWNER);
        // Log contract name
        console2.log(erc721Press.name());
        // Log contract symbol
        console2.log(erc721Press.symbol());
    }

    function test_mintWithEmptyData(uint16 mintQuantity) public setUpERC721PressBase {
        bytes memory mintData;
        // Remove the zero quantity mint edge case
        vm.assume(mintQuantity > 1);
        erc721Press.mintWithData(mintQuantity, mintData);
    }

    function test_mintWithData(uint16 mintQuantity) public setUpERC721PressBase {
        string memory testString = "testString";
        // Remove the zero quantity mint edge case        
        vm.assume(mintQuantity > 1);
        bytes memory mintData = abi.encode(testString);
        erc721Press.mintWithData(mintQuantity, mintData);
        assertEq(mockRenderer.tokenURI(1), testString);
        assertEq(erc721Press.tokenURI(1), testString);

        // Returns mockTokenUri
        console2.log(mockRenderer.tokenURI(1));
    }

    function test_defaultLogicSetup() public setUpPressDefaultLogic {
        vm.prank(address(ADMIN));
        defaultLogic.canUpdateConfig(address(erc721Press), ADMIN);
    }

}