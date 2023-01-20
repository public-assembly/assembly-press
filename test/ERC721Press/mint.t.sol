// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {PressConfig} from "../PressConfig.sol";
import {DefaultLogic} from "../../src/logic/DefaultLogic.sol";
import {MockRenderer} from "../mocks/MockRenderer.sol";

contract ERC721Press_mint is PressConfig {

    function test_mintWithEmptyData(uint64 mintQuantity) public setUpPressBase {
        address mintRecipient = address(0x03);
        bytes memory mintData = "";
        // Remove the zero quantity mint edge case
        vm.assume(mintQuantity > 1);
        pressBase.mintWithData(mintRecipient, mintQuantity, mintData);
    }

    function test_mintWithData() public setUpPressBase {
        address mintRecipient = address(0x03);
        uint64 mintQuantity = 1;
        bytes memory mintData = "0x01";
        pressBase.mintWithData(mintRecipient, mintQuantity, mintData);
        // Returns mockTokenUri
        console2.log(mockRenderer.tokenURI(1));
    }

    function test_mintToTheZeroAddress() public setUpPressBase {
        address mintRecipient = address(0);
        uint64 mintQuantity = 1;
        bytes memory mintData = "";
        vm.expectRevert();
        pressBase.mintWithData(mintRecipient, mintQuantity, mintData);
    }

    function test_defaultLogicSetup() public setUpPressDefaultLogic {
        vm.prank(address(ADMIN));
        defaultLogic.canUpdatePressConfig(address(pressBase), ADMIN);
    }

}
