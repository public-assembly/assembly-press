// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ILogic} from "../../../core/logic/ILogic.sol";

interface IDatabaseEngine {


    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||
    
    // Basic Info
    function name() external view returns (string memory);
    function owner() external view returns (address);

    /// @notice Getter for a single listing id
    function getListing(
        address targetPress,
        uint256 listingIndex
    ) external view returns (Listing memory);

    /// @notice Getter for a all listings
    function getListings(
        address targetPress
    ) external view returns (Listing[] memory activeListings);

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Event emitted when mint Settings updated
    /// @param press Press that initialized logic file
    /// @param mintPrice universal mint price for contract
    /// @param maxSupply Press maxSupply
    /// @param mintCapPerAddress Press mintCapPerAddress
    event SettingsUpdated(
        address indexed sender,
        address indexed press,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    );

    /// @notice Emitted when a listing is added
    event ListingAdded(
        address indexed targetPress,
        address indexed user,
        Listing listing
    );

    /// @notice Emitted when a listing is removed
    event ListingRemoved(
        address indexed targetPress,
        address indexed user,
        Listing listing
    );

    /// @notice A new logic contract is set
    event SetLogic(
        address indexed targetPress,
        Ilogic logic
    );

    /// @notice Database Pause has been udpated.
    event DatabasePauseUpdated(
        address indexed targetPress,
        address indexed pauser,
        bool isPaused
    );

    /// @notice Sort order has been updated
    event UpdatedSortOrder(
        address indexed targetPress,
        uint256[] ids,
        int32[] sorts,
        address updatedBy
    );

    /// @notice This contract is scheduled to be frozen
    event ScheduledFreeze(address indexed targetPress, uint256 timestamp);

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice Address does not have admin role
    error Not_Admin();
    /// @notice msg.sender does not have pause access for given Press
    error No_Pause_Access();
    /// @notice msg.sender does not have freeze access for given Press
    error No_Freeze_Access();
    /// @notice msg.sender does not have sort order access for given Press
    error No_SortOrder_Access();
    /// @notice Access not allowed by given user
    error ACCESS_NOT_ALLOWED();

    // Constraint/invalid/failure errors
    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice Cannot set address to the zero address
    error Cannot_Set_Zero_Address();
    /// @notice Data received by logic contract is not correct length
    error Invalid_Input_Data_Length();    
    /// @notice Cannot check results for given mint params
    error Invalid_Mint_Settings();
    /// @notice Protects maxSupply from breaking when swapping in new logic
    error Cannot_Set_MaxSupply_Below_TotalMinted();
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();
    /// @notice Role value is not available
    error Invalid_Role();
    /// @notice Action is unable to complete because the database is paused.
    error DATABASE_PAUSED();
    /// @notice The pause state needs to be toggled and cannot be set to it's current value.
    error CANNOT_SET_SAME_PAUSED_STATE();
    /// @notice Error attempting to update the database after it has been frozen
    error DATABASE_FROZEN();
    /// @notice attempt to get owner of an unowned / burned token
    error TOKEN_HAS_NO_OWNER();
}
