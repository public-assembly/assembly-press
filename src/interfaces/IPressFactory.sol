// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ILogic} from "./ILogic.sol";
import {IRenderer} from "./IRenderer.sol";

interface IPressFactory {
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

    /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
    function createPress(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        address payable _fundsRecipient,
        uint16 _royaltyBPS,
        ILogic _logic,
        bytes memory _logicInit,
        IRenderer _renderer,
        bytes memory _rendererInit,
        uint16 _primarySaleFeeBPS,
        address payable _primarySaleFeeRecipient
    ) external returns (address payable newPressAddress);
}
