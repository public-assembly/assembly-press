// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IRenderer} from "../../src/interfaces/IRenderer.sol";

contract MockRenderer is IRenderer {
    function tokenURI(uint256) external pure override returns (string memory) {
        return "mockTokenUri";
    }

    function contractURI() external pure override returns (string memory) {
        return "mockContractUri";
    }

    function initializeWithData(bytes memory rendererInit) external {}
    function initializeTokenMetadata(bytes memory tokenInit) external {}
}
