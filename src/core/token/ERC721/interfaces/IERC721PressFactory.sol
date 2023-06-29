// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/


import {IERC721PressLogic} from "./IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./IERC721PressRenderer.sol";
import {IERC721Press} from "./IERC721Press.sol";

interface IERC721PressFactory {
  
  // ||||||||||||||||||||||||||||||||
  // ||| ERRORS |||||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Implementation address cannot be set to zero
  error Address_Cannot_Be_Zero();

  // ||||||||||||||||||||||||||||||||
  // ||| EVENTS |||||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Emitted when the underlying Press impl is set in constructor
  event PressImplementationSet(address indexed pressImpl);

  /// @notice Emitted when the underlying Database impl is set in constructor
  event DatabaseImplementationSet(address indexed databaseImpl);

  /// @notice Emitted when a new Press is created
  event Create721Press(
    address indexed newPress,
    address indexed initialOwner,
    address indexed databaseImpl,
    IERC721Press.Settings settings
  );  
  
  // ||||||||||||||||||||||||||||||||
  // ||| FUNCTIONS ||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
  function createPress(
    string memory name,
    string memory symbol,
    address initialOwner,
    bytes memory databaseInit,
    IERC721Press.Settings memory settings
  ) external returns (address);
}
