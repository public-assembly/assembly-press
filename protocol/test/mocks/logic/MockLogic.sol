// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ILogic} from "../../../src/core/press/logic/ILogic.sol";

contract MockLogic is ILogic {

    // Mapping to keep track of initialized contracts
    mapping(address => bool) public isInitialized;

    function initializeWithData(bytes memory initData) external {
        isInitialized[msg.sender] = true;
    }
}
