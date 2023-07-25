// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// import {IERC721PressRenderer} from "../../../../src/core/token/ERC721/interfaces/IERC721PressRenderer.sol";
import {ERC721Press} from "../../../../src/core/token/ERC721/ERC721Press.sol";

contract MockLogic {
    // error caused by initialization not being called by Press database contract
    error UnauthorizedInitializer();

    mapping(address => bool) public pressInitializedInfo;

    function initializeWithData(address targetPress, bytes memory initData) external {
        if (msg.sender != address(ERC721Press(payable(targetPress)).getDatabase())) {
            revert UnauthorizedInitializer();
        }

        require(initData.length > 0, "shouldnt equal zero");

        pressInitializedInfo[targetPress] = true;
    }

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    function getMintPrice(address, address, uint256) external pure returns (uint256) {
        return 10000000000000000; // 0.01 eth in wei
    }

    /// @notice returns true/false access for a given Press + account + quantity
    function getMintAccess(address targetPress, address mintCaller, uint256 mintQuantity)
        external
        view
        returns (bool)
    {
        return true;
    }
}
