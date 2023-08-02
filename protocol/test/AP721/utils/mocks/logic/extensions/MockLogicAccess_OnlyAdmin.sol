// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAP721Logic} from "../../../../../../src/core/token/AP721/logic/interfaces/IAP721Logic.sol";
import {DatabaseGuard} from "../../../../../../src/core/utils/DatabaseGuard.sol";

contract MockLogic_OnlyAdmin is IAP721Logic, DatabaseGuard {
    constructor(address _databaseImpl) DatabaseGuard(_databaseImpl) {}

    mapping(address => address) public adminInfo;

    function initializeWithData(address target, bytes memory initData) external onlyDatabase {
        (address admin) = abi.decode(initData, (address));
        adminInfo[target] = admin;
    }

    function name() external view returns (string memory) {
        return "MockLogic_OnlyAdmin";
    }

    function getStoreAccess(address target, address sender, uint256 quantity) external view returns (bool) {
        if (adminInfo[target] == sender) return true;
        return false;
    }

    function getOverwriteAccess(address target, address sender, uint256 tokeknId) external view returns (bool) {
        if (adminInfo[target] == sender) return true;
        return false;
    }

    function getRemoveAccess(address target, address sender, uint256 tokeknId) external view returns (bool) {
        if (adminInfo[target] == sender) return true;
        return false;
    }

    function getSettingsAccess(address target, address sender) external view returns (bool) {
        if (adminInfo[target] == sender) return true;
        return false;
    }

    function getContractDataAccess(address target, address sender) external view returns (bool) {
        if (adminInfo[target] == sender) return true;
        return false;
    }
}
