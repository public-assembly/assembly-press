// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";

import {ILogic} from "./ILogic.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";

/**
* @title RolesWith721Gate_ImmutableMetadata_NoFees
* @notice Facilitates role based access control for admin/manager roles, and erc721 ownership based access for user role
* @notice Facilitates mint pricing + supply logic. Price = free, supply = unlimited (capped by uint256 max value)
* @notice Facilitates metadata mutability logic. Token metadata cannot be adjusted after set
* @author Max Bochman
*/
contract RolesWith721Gate_ImmutableMetadata_NoFees is ILogic {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    /// @notice Shared struct tracking Press settings in logic
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * erc721gate (20) + frozenAt (10) + isPaused (1) = 31 bytes 
     */
    struct Settings {
        /// @notice Address of the ERC721 contract used for gating
        address erc721Gate;  
        /// @notice Timestamp that the Press database is frozen at (if never, frozen = 0)
        uint80 frozenAt;                      
        /// @notice If database is paused by the owner
        bool isPaused;        
    }    

    /// @notice Shared struct used to store role data for a given Press
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * account (20) + role (1) = 21 bytes
    */    
    struct RoleDetails {
        address account;
        uint8 role;
    }     

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string immutable public name = "RolesWith721Gate_NoFee";

    // Role constants
    uint8 constant public ADMIN = 3;
    uint8 constant public MANAGER = 2;
    uint8 constant public USER = 1;
    uint8 constant public NO_ROLE = 0;    

    // Press contract to Setttings {erc721Gate, frozenAt, isPaused} 
    mapping(address => Settings) public settingsInfo;

    // Press contract to account to role for determining admin/manager functionality
    mapping(address => mapping(address => uint8)) public roleInfo;    

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Account does not have admin role
    error RequiresAdmin();
    /// @notice Account does not have high enough role
    error RequiresHigherRole();
    /// @notice Invalid role being assigned
    error CanOnlyAssignAdminOrManager();    
    /// @notice Initialization coming from unauthorized contract
    error UnauthorizedInitializer();
    /// @notice Database write access if frozen forever
    error DatabaseFrozen();
    /// @notice Database write access is temporarily paused for certain roles
    error DatabasePaused();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when erc721Gate address updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param erc721Gate address set for erc721Gate
    event Erc721GateUpdated(
        address targetPress,
        address sender,
        address erc721Gate
    );            

    /// @notice Event emitted when isPaused status updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param isPaused isPaused true/false bool
    event IsPausedUpdated(
        address targetPress,
        address sender,
        bool isPaused
    );       

    /// @notice Event emitted when frozenAt status updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param frozen unix timestamp in seconds
    event FrozenAtdUpdated(
        address targetPress,
        address sender,
        uint80 frozenAt
    );           

    /// @notice Event emitted when a new admin/manager/no_role role is assigned
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param account account receiving new role
    /// @param role role being assigned
    event RoleAssigned(
        address targetPress,
        address sender,
        address account,
        uint8 role 
    );    

    /// @notice Event emitted when a role is revoked from an account
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param account account being revoked
    /// @param role account role be updated to NO_ROLE
    event RoleRevoked(
        address targetPress,
        address sender,
        address account,
        uint8 role 
    );         

    //////////////////////////////////////////////////
    // MODIFIERS
    //////////////////////////////////////////////////    

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdmin(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin
        return roleInfo[targetPress][account] != ADMIN ? false : true;
    }

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdminOrManager(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin or manager
        return roleInfo[targetPress][account] != NO_ROLE ? true : false;
    }        
    
    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved admin of target Press (from msg.sender)
    modifier onlyAdmin(address targetPress) {
        if (!_isAdmin(targetPress, msg.sender)) {
            revert RequiresAdmin();
        }

        _;
    }

    /// @notice Only allowed for contract admin
    /// @param targetPress target Press 
    /// @dev only allows approved managers or admins of targetPress (from msg.sender)
    modifier onlyAdminOrManager(address targetPress) {
        if (!_isAdminOrManager(targetPress, msg.sender)) {
            revert RequiresHigherRole();
        }

        _;
    }        

    /// @notice Modifier that ensures database functionality not frozen
    modifier NotFrozen(address targetPress) {
           
        // Check if Press database is frozen
        if (settingsInfo[targetPress].frozenAt != 0 && settingsInfo[targetPress].frozenAt < block.timestamp) {
            revert DatabaseFrozen();
        }

        _;     
    }  

    //////////////////////////////////////////////////
    // INITIALIZER
    //////////////////////////////////////////////////

    /// @notice Initializes Press settings 
    /// @dev Can only be called by the database contract for a given Press
    /// @dev Called during the initialization process for a given Press
    function initializeWithData(address targetPress, bytes memory data) external {

        // Ensure that only the expected database contract is calling this function
        if (msg.sender != address(ERC721Press(targetPress).getDatabase())) {
            revert UnauthorizedInitializer();
        }

        // data format: erc721Gate, isPaused, initialRoles
        (
            address er721Gate, 
            bool isPaused,            
            RoleDetails[] memory initialRoles
        ) = abi.decode(data, (address, bool, RoleDetails[]));

        // assign initial roles for Press
        _assignRoles(targetPress, initialRoles);

        // configure settings for Press
        _setTokenGate(er721Gate);
        _setIsPaused(isPaused);
    }

    //////////////////////////////////////////////////
    // ROLE ASSIGNMENT
    //////////////////////////////////////////////////    

    /////////////
    // EXTERNAL
    /////////////    

    /// @notice Assign new roles for given accounts for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs to assign
    function assignRoles(address targetPress, RoleDetails[] memory roleDetails) 
        onlyAdmin(targetPress) 
        external
    {
        _assignRoles(targetPress, roleDetails);
    }    

    /// @notice Revokes roles for given Press 
    /// @param targetPress target Press
    /// @param accounts array of addresses to revoke roles from
    function revokeRoles(address targetPress, address[] memory accounts) 
        onlyAdmin(targetPress) 
        external
    {
        // revoke roles from each account provided
        for (uint256 i; i < accounts.length; ++i) {
            // revoke role from account
            roleInfo[targetPress][accounts[i]] = NO_ROLE;

            emit RoleRevoked({
                targetPress: targetPress,
                sender: msg.sender,
                account: accounts[i],
                role: NO_ROLE
            });
        }    
    }  

    /////////////
    // INTERNAL
    /////////////      

    /// @notice internal assign new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function _assignRoles(address targetPress, RoleDetails[] memory roleDetails) internal {
        // assign roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being assigned is a valid role
            if (roleDetails[i].role != ADMIN && roleDetails[i].role != MANAGER) {
                revert CanOnlyAssignAdminOrManager();
            }
            // assign role to account
            roleInfo[targetPress][roleDetails[i].account] = roleDetails[i].role;

            emit RoleAssigned({
                targetPress: targetPress,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }    
    }           

    //////////////////////////////////////////////////
    // SETTINGS
    //////////////////////////////////////////////////      

    /////////////
    // EXTERNAL
    /////////////

    /// @notice Set the address of the erc721Gate in use for a given targetPress
    /// @dev msg.sender must have ADMIN role
    /// @param targetPress target Press index
    /// @param erc721Gate address for the erc721Gate
    function setErc721Gate(address targetPress, address erc721Gate) external onlyAdmin(targetPress) {
        _setErc721Gate(targetPress, erc721Gate);
    }    

    /// @notice Set the bool of the isPaused status for a given targetPress
    /// @dev msg.sender must have ADMIN role
    /// @param targetPress target Press index
    /// @param isPaused address for the erc721Gate
    function setIsPaused(address targetPress, bool isPaused) external onlyAdmin(targetPress) {
        _setIsPaused(targetPress, isPaused);
    }        

    /// @notice Set the frozenAt time for a given targetPress
    /// @dev restricts all write access (except burning) to a givenPress starting from a given Unix timestamp => forever
    /// @dev frozenAt = 0 means no frozen time has been set for Press
    /// @dev frozenAt!= 0 && frozenAt < block.timeStamp means frozen time has been set but write access still accessible for Press
    /// @dev msg.sender must have ADMIN role
    /// @param targetPress target Press index
    /// @param frozenAt timestamp in Unix seconds
    function setFrozenAt(address targetPress, uint80 frozenAt) external onlyAdmin(targetPress) {
        _setFrozenAt(targetPress, frozenAt);
    }          

    /////////////
    // INTERNAL
    /////////////

    /// @notice Internal handler for updates to the address of the tokenGate in use for a given targetPress
    /// @dev No access checks, enforce elsewhere
    /// @param targetPress target Press index
    /// @param tokenGate address for the tokenGate
    function _setErc721Gate(address targetPress, address erc721Gate) internal {
        settingsInfo[targetPress].erc721Gate = erc721Gate;

        emit Erc721GateUpdated({
            targetPress: targetPress,
            sender: msg.sender,
            newErc721Gate: erc721Gate
        });
    }        

    /// @notice Internal handler for updates to isPaused status for a given targetPress
    /// @dev No access checks, enforce elsewhere
    /// @param targetPress target Press index
    /// @param isPaused true/false value for isPaused
    function _setIsPaused(address targetPress, bool isPaused) internal {
        settingsInfo[targetPress].isPaused = isPaused;

        emit IsPausedUpdated({
            targetPress: targetPress,
            sender: msg.sender,
            isPaused: isPaused
        });
    }        

    /// @notice Internal handler for updates to frozenAt status for a given targetPress
    /// @dev No access checks, enforce elsewhere
    /// @param targetPress target Press index
    /// @param isFrozen timestamp in unix seconds value
    function _setIsFrozen(address targetPress, uint80 frozenAt) internal {
        settingsInfo[targetPress].frozenAt = frozenAt;

        emit frozenAt({
            targetPress: targetPress,
            sender: msg.sender,
            frozenAt: frozenAt
        });
    }           

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice returns access level of a given account for a given Press
    function getAccessLevel(address accessMappingTarget, address accountToGetAccessFor)
        external
        view
        returns (uint256)
    {   
        return _getAccessLevel(accessMappingTarget, accountToGetAccessFor);
    }

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    function getMintPrice(address accessMappingTarget, address accountToGetAccessFor, uint256 mintQuantity)
        external
        view
        returns (uint256)
    {    
        return _getMintPrice(accessMappingTarget, accountToGetAccessFor, mintQuantity);
    }   

    function getMintAccess(address accessMappingTarget, address mintCaller, uint256 mintQuantity)
        external
        view
        NotFrozen(accessMappingTarget)
        returns (bool)
    {   
        // Check if Press database is paused and mintCaller doesn't have role override
        if (settingsInfo[targetPress].isPaused) {
            if (roleInfo[targetPress][mintCaller] == NO_ROLE) {
                revert DatabasePaused();
            }
        }

        if (_getAccessLevel(accessMappingTarget, mintCaller) != 0) {
            return true;
        } else {
            return false;
        }
    }    

    function getBurnAccess(address accessMappingTarget, address burnCaller, uint256 tokenId)
        external
        view
        NotFrozen(accessMappingTarget)
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, burnCaller) < MANAGER) {
            return true;
        } else {
            return false;
        }
    }        

    function getSortAccess(address accessMappingTarget, address sortCaller)
        external
        view
        NotFrozen(accessMappingTarget)
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, sortCaller) < MANAGER) {
            return false;
        } else {
            return true;
        }
    }    

    function getSettingsAccess(address accessMappingTarget, address settingsCaller)
        external
        view
        NotFrozen(accessMappingTarget)
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, settingsCaller) == ADMIN) {
            return true;
        } else {
            return false;
        }
    }    

    function getPaymentsAccess(address accessMappingTarget, address paymentsCaller)
        external
        view
        NotFrozen(accessMappingTarget)
        returns (bool)
    {
        if (_getAccessLevel(accessMappingTarget, paymentsCaller) == ADMIN) {
            return true;
        } else {
            return false;
        }
    }     

    function getDataAccess(address accessMappingTarget, address metadataCaller, uint256 tokenId)
        external
        view
        returns (bool)
    {
        // All token metadata is immutable once stored
        return false;
    }

    /////////////
    // INTERNAL
    /////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function _getAccessLevel(address accessMappingTarget, address accountToGetAccessFor)
        internal
        view
        returns (uint256)
    {
        // cache role for given target address
        uint8 role = roleInfo[accessMappingTarget][accountToGetAccessFor];

        // first check if address has admin/manager role, return that role if it does
        // if no admin/manager role, check if address has a balance of > 0 of the tokenGate contract, return 1 if it does
        // return 0 if all of the above is false
        if (role != NO_ROLE) {
            return role;
        } else if (IERC721(tokenGateInfo[accessMappingTarget]).balanceOf(accountToGetAccessFor) != 0) {
            return USER;
        } else {
            return 0;
        }
    }        

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    /// @dev called via the database contract that has been set for a given Press
    function _getMintPrice(address accessMappingTarget, address accountToGetAccessFor, uint256 mintQuantity)
        internal
        view
        returns (uint256)
    {
        // always returns 0. no ability to change mint price with this logic contract
        return 0;
    }        
}