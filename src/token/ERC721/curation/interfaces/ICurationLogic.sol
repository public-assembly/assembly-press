// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControlRegistry} from "../../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

/**
 * CurationLogic interface
 */
interface ICurationLogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Shared listing struct for both access and storage.
    /* 
    Struct Breakdown
    curatedAddress - 20 bytes
    selectedTokenId - 12 bytes => curatedAddress + selectedTokenId = 32 bytes (perfectly fills the first slot)
    curator - 20 bytes
    sortOrder - 4 bytes
    chainId - 2 bytes
    curationTargetType - 2 bytes
    hasTokenId - 1 bytes => curator + sortOrder + chainId + curationTargetType + hasTokenId = 29 bytes, packed into one 32-byte slot (with 3 bytes padding)
    */        
    struct Listing {
        /// @notice Address that is curated
        address curatedAddress;
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint96 selectedTokenId;
        /// @notice Address that curated this entry
        address curator;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int32 sortOrder;
        /// @notice ChainID for curated contract
        uint16 chainId;
        /// @notice Curation type (see public getters on contract for list of types)
        uint16 curationTargetType;
        /// @notice If the token ID applies to the curation (can be whole contract or a specific tokenID)
        bool hasTokenId;    
    }    

    /// @notice Shared config struct tracking curation status
    struct Config {
        /// @notice Address of the accessControl contract
        IAccessControlRegistry accessControl;    
        /// @notice If curation is paused by the owner
        bool isPaused;        
        /// @notice timestamp that the curation is frozen at (if never, frozen = 0)
        uint256 frozenAt;                
        /// @notice price to curate per listing
        uint256 priceToCurate;                        
        /// Stores virtual mapping array length parameters
        /// @notice Array total size (total size)
        uint40 numAdded;
        /// @notice Array active size = numAdded - numRemoved
        /// @dev Blank entries are retained within array
        uint40 numRemoved;
        /// @notice initialized uint. 0 = not initialized, 1 = initialized
        uint8 initialized;        
    }
    
    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    
    
    /// @notice Convience getter for Generic/unknown types (default 0). Used for metadata as well.
    function CURATION_TYPE_GENERIC() external view returns (uint16);
    /// @notice Convience getter for NFT contract types. Used for metadata as well.
    function CURATION_TYPE_NFT_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for generic contract types. Used for metadata as well.
    function CURATION_TYPE_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for curation contract types. Used for metadata as well.
    function CURATION_TYPE_CURATION_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for NFT item types. Used for metadata as well.
    function CURATION_TYPE_NFT_ITEM() external view returns (uint16);
    /// @notice Convience getter for wallet types. Used for metadata as well.
    function CURATION_TYPE_WALLET() external view returns (uint16);

    /// @notice Getter for a single listing id
    function getListing(address targetPress, uint256 listingIndex) external view returns (Listing memory);
    /// @notice Getter for a all listings
    function getListings(address targetPress) external view returns (Listing[] memory activeListings);
    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListingsForCurator(address targetPress, address curator) external view returns (Listing[] memory activeListings);    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when mint config updated
    /// @param press Press that initialized logic file
    /// @param mintPrice universal mint price for contract
    /// @param maxSupply Press maxSupply
    /// @param mintCapPerAddress Press mintCapPerAddress
    event ConfigInitialized(
        address indexed press,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    );    

    /// @notice Event emitted when mint config updated
    /// @param press Press that initialized logic file
    /// @param mintPrice universal mint price for contract
    /// @param maxSupply Press maxSupply
    /// @param mintCapPerAddress Press mintCapPerAddress
    event ConfigUpdated(
        address indexed sender,
        address indexed press,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    );  

    /// @notice Emitted when a listing is added
    event ListingAdded(address indexed targetPress, address indexed curator, Listing listing);

    /// @notice Emitted when a listing is removed
    event ListingRemoved(address indexed targetPress, address indexed curator, Listing listing);

    /// @notice A new accessControl is set
    event SetAccessControl(address indexed targetPress, IAccessControlRegistry accessControl);

    /// @notice Curation Pause has been udpated.
    event CurationPauseUpdated(address indexed targetPress, address indexed pauser, bool isPaused);

    /// @notice Sort order has been updated
    event UpdatedSortOrder(address indexed targetPress, uint256[] ids, int32[] sorts, address updatedBy);

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
    /// @notice Wrong curator for the listing when attempting to access the listing.
    error WRONG_CURATOR_FOR_LISTING(address setCurator, address expectedCurator);
    /// @notice Access not allowed by given user
    error ACCESS_NOT_ALLOWED();    

    // Constraint/invalid/failure errors    
    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice Cannot set address to the zero address
    error Cannot_Set_Zero_Address();
    /// @notice Cannot check results for given mint params
    error Invalid_Mint_Config();
    /// @notice Protects maxSupply from breaking when swapping in new logic
    error Cannot_Set_MaxSupply_Below_TotalMinted();
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();
    /// @notice Role value is not available 
    error Invalid_Role();    
    /// @notice Action is unable to complete because the curation is paused.
    error CURATION_PAUSED();
    /// @notice The pause state needs to be toggled and cannot be set to it's current value.
    error CANNOT_SET_SAME_PAUSED_STATE();
    /// @notice Error attempting to update the curation after it has been frozen
    error CURATION_FROZEN();
    /// @notice attempt to get owner of an unowned / burned token
    error TOKEN_HAS_NO_OWNER();
    /// @notice Array input lengths don't match for sort orders
    error INVALID_INPUT_LENGTH();
    /// @notice Curation limit can only be increased, not decreased.
    error CANNOT_UPDATE_CURATION_LIMIT_DOWN();
}