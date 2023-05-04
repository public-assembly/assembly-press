// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title IDualOwnableUpgradeable
/// @author Max Bochman
/// @notice The external Ownable events, errors, and functions
interface IDualOwnableUpgradeable {
    
    ///                                                          ///
    ///                            EVENTS                        ///
    ///                                                          ///

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when secondary ownership has been updated
    /// @param prevSecondaryOwner The previous secondary owner address
    /// @param newSecondaryOwner The new secondary owner address
    event SecondaryOwnerUpdated(address indexed prevSecondaryOwner, address indexed newSecondaryOwner);    

    ///                                                          ///
    ///                            ERRORS                        ///
    ///                                                          ///

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();
    /// @dev Reverts if an unauthorized user calls an eitherOwner function
    error NOT_EITHER_OWNER();    
    /// @dev Owner cannot be the zero/burn address
    error OWNER_CANNOT_BE_ZERO_ADDRESS();

    ///                                                          ///
    ///                           FUNCTIONS                      ///
    ///                                                          ///

    /// @notice The address of the owner
    function owner() external view returns (address);

    /// @notice The address of the secondary owner
    function secondaryOwner() external view returns (address);

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;

    /// @notice Forces a secondary ownership transfer
    /// @param newSecondaryOwner The new secondary owner address
    function transferSecondaryOwnership(address newSecondaryOwner) external;    
}