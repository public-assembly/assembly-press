// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAP721Logic} from "../../../../src/core/token/AP721/interfaces/IAP721Logic.sol";

contract MockLogic is IAP721Logic { 

    function initializeWithData(address target, bytes memory initData) external {
        return;
    }

    function name() external view returns (string memory) {
        return "MockLogic";
    }

    function getStoreAccess(address target, address sender, uint256 quantity) external view returns (bool) {
        return true;
    }

    function getOverwriteAccess(address target, address sender, uint256 tokeknId) external view returns (bool) {
        return true;
    }

    function getRemoveAccess(address target, address sender, uint256 tokeknId) external view returns (bool) {
        return true;
    }           

    function getSettingsAccess(address target, address sender) external view returns (bool) {
        return true;
    }

    function getContractDataAccess(address targetPress, address metadataCaller) external view returns (bool) {
        return true;
    }      
}