// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {PressConfig} from "./utils/PressConfig.sol";
import {DefaultLogic} from "../../../src/tokens/ERC721/logic/DefaultLogic.sol";
import {MockRenderer} from "./mocks/MockRenderer.sol";

contract ERC721Press_mint is PressConfig {

    function test_mintWithEmptyData(uint16 mintQuantity) public setUpPressBase {
        address mintRecipient = address(0x03);
        bytes memory mintData;
        // Remove the zero quantity mint edge case
        vm.assume(mintQuantity > 1);
        erc721Press.mintWithData(mintRecipient, mintQuantity, mintData);
    }

    function test_mintWithData(uint16 mintQuantity) public setUpPressBase {
        address mintRecipient = address(0x03);
        string memory testString = "testString";
        // Remove the zero quantity mint edge case        
        vm.assume(mintQuantity > 1);
        bytes memory mintData = abi.encode(testString);
        erc721Press.mintWithData(mintRecipient, mintQuantity, mintData);
        assertEq(mockRenderer.tokenURI(1), testString);
        assertEq(erc721Press.tokenURI(1), testString);

        // Returns mockTokenUri
        console2.log(mockRenderer.tokenURI(1));
    }

    function test_mintToTheZeroAddress() public setUpPressBase {
        address mintRecipient = address(0);
        uint16 mintQuantity = 1;
        bytes memory mintData = "";
        vm.expectRevert();
        erc721Press.mintWithData(mintRecipient, mintQuantity, mintData);
    }

    function test_defaultLogicSetup() public setUpPressDefaultLogic {
        vm.prank(address(ADMIN));
        defaultLogic.canUpdatePressConfig(address(erc721Press), ADMIN);
    }

}
