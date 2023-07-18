// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAP721Renderer} from "../../../../src/core/token/AP721/interfaces/IAP721Renderer.sol";


contract MockRenderer is IAP721Renderer { 

    function initializeWithData(address targetPress, bytes memory initData) external {
        return;
    }

    function getTokenURI(address target, uint256 tokenId) external view returns (string memory) {
        return "TOKEN_URI";
    }

    function getContractURI(address target) external view returns (string memory) {
        return "CONTRACT_URI";
    }
}