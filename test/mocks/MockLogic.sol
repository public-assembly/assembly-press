// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ILogic} from "../../src/interfaces/ILogic.sol";

contract MockLogic is ILogic {
    
    function initializeWithData(bytes memory initData) external {}

    function canUpdatePressConfig(address targetPress, address updateCaller) external view returns (bool) {}

    function canMint(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (bool) {
        return true;
    }

    function canEditMetadata(address targetPress, address editCaller) external view returns (bool) {}

    function canWithdraw(address targetPress, address withdrawCaller) external view returns (bool) {}

    function canBurn(address targetPress, uint256 tokenId, address burnCaller) external view returns (bool) {}

    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool) {}

    function canTransfer(address targetPress, address transferCaller) external view returns (bool) {}

    function totalMintPrice(address targetPress, uint64 mintQuantity, address mintCaller)
        external
        view
        returns (uint256)
    {}

    function isInitialized(address targetPress) external view returns (bool) {}

    function maxSupply() external view returns (uint64) {}
}
