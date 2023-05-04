// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IDualOwnableUpgradeable} from "./IDualOwnableUpgradeable.sol";
import {DualOwnableStorageV1} from "./DualOwnableStorageV1.sol";
import {Initializable} from "../../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title DualOwnableUpgradeable
/// @author Max Bochman
/// @notice Modified from ZORA Ownable2StepUpgradeable
/// - Uses custom errors declared in IOwnable
/// - Adds `secondaryOwner` whose privilages can be revoked by `owner` + `eitherOwner` modifier
abstract contract DualOwnableUpgradeable is IDualOwnableUpgradeable, DualOwnableStorageV1, Initializable {

    ///                                                          ///
    ///                           MODIFIERS                      ///
    ///                                                          ///

    /// @dev Ensures the caller is the primary owner
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert ONLY_OWNER();
        }
        _;
    }

    /// @dev Ensures the caller is either owner or _secondaryOwner
    modifier eitherOwner() {
        address sender = msg.sender;
        if (sender != _owner && sender != _secondaryOwner) {
            revert NOT_EITHER_OWNER();
        }
        _;
    }    

    /// @dev Modifier to check if the address argument is the zero/burn address
    modifier notZeroAddress(address check) {
        if (check == address(0)) {
            revert OWNER_CANNOT_BE_ZERO_ADDRESS();
        }
        _;
    }
    

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @dev Initializes contract ownership
    /// @param _initialOwner The initial owner address
    function __Ownable_init(address _initialOwner) internal notZeroAddress(_initialOwner) onlyInitializing {
        _owner = _initialOwner;

        emit OwnerUpdated(address(0), _initialOwner);
    }

    /// @dev Initializes contract ownership
    /// @param _initialSecondaryOwner The initial secondary owner address
    function __Secondary_Ownable_init(address _initialSecondaryOwner) internal notZeroAddress(_initialSecondaryOwner) onlyInitializing {
        _secondaryOwner = _initialSecondaryOwner;

        emit SecondaryOwnerUpdated(address(0), _initialSecondaryOwner);
    }

    /// @notice The address of the owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @notice The address of the secondary owner
    function secondaryOwner() public view returns (address) {
        return _secondaryOwner;
    }

    /// @notice Forces an ownership transfer from the last owner
    /// @param _newOwner The new owner address
    function transferOwnership(address _newOwner) public notZeroAddress(_newOwner) onlyOwner {
        _transferOwnership(_newOwner);
    }

    /// @notice Forces an ownership transfer from any sender
    /// @param _newOwner New owner to transfer contract to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferOwnership(address _newOwner) internal {
        emit OwnerUpdated(_owner, _newOwner);

        _owner = _newOwner;
    }    

    /// @notice Forces a secondary ownership transfer from the last secondary owner
    /// @param _newSecondaryOwner The new secondary owner address
    function transferSecondaryOwnership(address _newSecondaryOwner) public notZeroAddress(_newSecondaryOwner) onlyOwner {
        _transferSecondaryOwnership(_newSecondaryOwner);
    }        

    /// @notice Forces a secondary ownership transfer from any sender
    /// @param _newSecondaryOwner New secondary owner to change _secondaryOwner to
    /// @dev Ensure is called only from trusted internal code, no access control checks.
    function _transferSecondaryOwnership(address _newSecondaryOwner) internal {
        emit SecondaryOwnerUpdated(_secondaryOwner, _newSecondaryOwner);

        _secondaryOwner = _newSecondaryOwner;
    }        

    /// @notice Resign ownership of contract
    /// @dev only callably by the owner, dangerous call.
    function resignOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Resign secondary ownership of contract
    /// @dev callable by either owner, dangerous call.
    function resignSecondaryOwnership() public eitherOwner {
        _transferSecondaryOwnership(address(0));
    }        
}
