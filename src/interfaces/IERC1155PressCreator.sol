// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155PressContractLogic} from "./IERC1155PressContractLogic.sol";

interface IERC1155PressCreator {
    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Implementation address cannot be set to zero
    error Address_Cannot_Be_Zero();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Emitted when a Press instance is initialized
    event PressInitialized(address indexed pressImpl);

    /// @notice Emitted when the PressFactory is initialized
    event PressFactoryInitialized();

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Initializes the proxy behind a PressFactory
    function initialize(address _initialOwner) external;

    /// @notice Creates a new, creator-owned proxy of `ERC1155Press.sol`
    function createERC1155Press(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        IERC1155PressContractLogic _logic,
        bytes memory _logicInit
    ) external returns (address payable newPressAddress);
}
