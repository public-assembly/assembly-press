// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAP721Renderer} from "../../../../../src/core/token/AP721/interfaces/IAP721Renderer.sol";
import {DatabaseGuard} from "../../../../../src/core/utils/DatabaseGuard.sol";


contract MockRenderer is IAP721Renderer, DatabaseGuard { 

    constructor(address _databaseImpl) DatabaseGuard(_databaseImpl) {}

    // Mapping to keep track of initialized contracts
    mapping(address => bool) public isInitialized;

    function initializeWithData(address targetPress, bytes memory initData) onlyDatabase external {
        isInitialized[targetPress] = true;
    }

    function getTokenURI(address target, uint256 tokenId) external view returns (string memory) {
        return "TOKEN_URI";
    }

    function getContractURI(address target) external view returns (string memory) {
        return "CONTRACT_URI";
    } 
}