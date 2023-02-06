// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721PressLogic} from "../../../src/token/ERC721/interfaces/IERC721PressLogic.sol";

contract MockLogic is IERC721PressLogic {
    
    bytes storageTest;

    function initializeWithData(bytes memory initData) external {
        storageTest = initData;
    }

    function updateLogicWithData(address targetPress, bytes memory logicData) external {}

    function canUpdateConfig(address targetPress, address updateCaller) external view returns (bool) {}

    function canMint(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (bool) {
        return true;
    }

    function canEditMetadata(address targetPress, address editCaller) external view returns (bool) {
        return true;
    }

    function canWithdraw(address targetPress, address withdrawCaller) external view returns (bool) {
        return true;
    }

    function canBurn(address targetPress, uint256 tokenId, address burnCaller) external view returns (bool) {
        return true;
    }

    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool) {
        return true;
    }

    function canTransfer(address targetPress, address transferCaller) external view returns (bool) {
        return true;
    }

    function totalMintPrice(address targetPress, uint64 mintQuantity, address mintCaller)
        external
        view
        returns (uint256)
    {
        0.01 ether;
    }

    function isInitialized(address targetPress) external view returns (bool) {
        return true;
    }

    function maxSupply() external view returns (uint64) {
        return type(uint64).max;
    }
}
