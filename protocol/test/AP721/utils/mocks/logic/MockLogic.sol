// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAP721Logic} from "../../../../../src/core/token/AP721/logic/interfaces/IAP721Logic.sol";
import {DatabaseGuard} from "../../../../../src/core/utils/DatabaseGuard.sol";

contract MockLogic is IAP721Logic, DatabaseGuard {
    constructor(address _databaseImpl) DatabaseGuard(_databaseImpl) {}

    // Mapping to keep track of initialized contracts
    mapping(address => bytes) public isInitialized;

    function initializeWithData(address target, bytes memory initData) external onlyDatabase {
        isInitialized[target] = initData;        
    }
}
