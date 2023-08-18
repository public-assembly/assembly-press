// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IRenderer} from "../../../src/core/press/renderer/IRenderer.sol";

contract MockRenderer is IRenderer {

    // Mapping to keep track of initialized contracts
    mapping(address => bool) public isInitialized;

    function initializeWithData(bytes memory initData) external {
        isInitialized[msg.sender] = true;
    }
}
