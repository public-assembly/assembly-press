// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721PressRenderer} from "../../../../src/core/token/ERC721/interfaces/IERC721PressRenderer.sol";

contract MockRenderer is IERC721PressRenderer { 

    mapping(address => bool) public pressInitializedInfo;

    function initializeWithData(address targetPress, bytes memory initData) external {
        require(initData.length > 0, "shouldnt equal zero");

        pressInitializedInfo[msg.sender] = true;
    }

    function getTokenURI(address targetPress, uint256 tokenId) external view returns (string memory) {
        return "DEMO";
    }

    function getContractURI(address targetPress) external view returns (string memory) {
        return "DEMO";
    }
}