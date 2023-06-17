// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";

import {ILogic} from "./ILogic.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";

/**
* @title RolesWith721Gate_NoFee
* @notice Facilitates role based access control for admin/manager roles, and erc721 ownership based access for user role
* @notice Also handles mint pricing + supply logic. Price = free, supply = unlimited (capped by uint256 max value)
* @author Max Bochman
*/
contract RolesWith721Gate_NoFee is ILogic {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "RolesWith721Gate_NoFee";

    // Role constants
    uint8 constant ADMIN = 3;
    uint8 constant MANAGER = 2;
    uint8 constant USER = 1;
    uint8 constant NO_ROLE = 0;    

    // Press contract to ERC721 being used to gate user functionality
    mapping(address => address) public tokenGateInfo;

    // Press contract to account to role for determining admin/manager functionality
    mapping(address => mapping(address => uint8)) public roleInfo;    

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
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

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when tokenGate address updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param newGate new address set for tokenGate
    event TokenGateUpdated(
        address targetPress,
        address sender,
        address newGate
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
    // ADMIN
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

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    /// @dev data format: admin
    function initializeWithData(address targetPress, bytes memory data) external {

        // Ensure that only the expected database contract is calling this function
        if (msg.sender != address(ERC721Press(targetPress).getDatabase())) {
            revert UnauthorizedInitializer();
        }

        // abi.decode initial gate information set on logic initialization
        (address tokenGate, RoleDetails[] memory initialRoles) = abi.decode(data, (address, RoleDetails[]));

        // call internal assign roles function 
        _assignRoles(targetPress, initialRoles);

        // check if tokenGate was set to non zero address and update its value + emit event if it was
        if (tokenGate != address(0)) {
            tokenGateInfo[targetPress] = tokenGate;
            emit TokenGateUpdated(targetPress, msg.sender, tokenGate);
        }
    }

    //////////////////////////////////////////////////
    // ROLE DESIGNATION
    //////////////////////////////////////////////////    

    /// @notice Assign new roles for given accounts for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
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

    /// @notice Changes the address of the tokenGate in use for a given targetPress
    /// @param targetPress target Press index
    /// @param tokenGate address for the tokenGate
    function setTokenGate(address targetPress, address tokenGate) external onlyAdmin(targetPress) {
        tokenGateInfo[targetPress] = tokenGate;

        emit TokenGateUpdated({
            targetPress: targetPress,
            sender: msg.sender,
            newGate: tokenGate
        });
    }    

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
    // VIEW FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address accessMappingTarget)
        external
        view
        returns (uint256)
    {   
        return _getAccessLevel(accessMappingTarget, accessMappingTarget);
    }


    /// @notice returns mintPrice for a given Press + account + mintQuantity
    /// @dev called via the logic contract that has been set for a given Press
    function getMintPrice(address accessMappingTarget, address accessMappingTarget, uint256 mintQuantity)
        external
        view
        returns (uint256)
    {    
        return _getMintPrice(accessMappingTarget, accessMappingTarget, mintQuantity);
    }

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function _getAccessLevel(address accessMappingTarget, address accessMappingTarget)
        internal
        view
        returns (uint256)
    {
        // cache role for given target address
        uint8 role = roleInfo[accessMappingTarget][accessMappingTarget];

        // first check if address has admin/manager role, return that role if it does
        // if no admin/manager role, check if address has a balance of > 0 of the tokenGate contract, return 1 if it does
        // return 0 if all of the above is false
        if (role != NO_ROLE) {
            return role;
        } else if (IERC721(tokenGateInfo[accessMappingTarget]).balanceOf(accessMappingTarget) != 0) {
            return USER;
        } else {
            return 0;
        }
    }    

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    /// @dev called via the logic contract that has been set for a given Press
    function _getMintPrice(address accessMappingTarget, address accessMappingTarget, uint256 mintQuantity)
        internal
        view
        returns (uint256)
    {
        // always returns zero to hardcode no fee necessary
        return 0;
    }        

    function getMintAccess(address accessMappingTarget, address mintCaller, uint256 mintQuantity)
        external
        view
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, mintCaller) != 0) {
            return true;
        } else {
            return false;
        }
    }

    function getBurnAccess(address accessMappingTarget, address burnCaller, uint256 tokenId)
        external
        view
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, burnCaller) == ADMIN) {
            return true;
        } else {
            return false;
        }
    }

    function getSortAccess(address accessMappingTarget, address sortCaller)
        external
        view
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
        returns (bool)
    {   
        if (_getAccessLevel(accessMappingTarget, settingsCaller) < ADMIN) {
            return false;
        } else {
            return true;
        }
    }        

    function getMetadataAccess(address accessMappingTarget, address metadataCaller, uint256 tokenId)
        external
        view
        returns (bool)
    {
        // All token metadata is immutable once stored. Can only be deleted by burning token
        return false;
    }

    function getPauseAccess(address accessMappingTarget, address txnCaller)
        external
        view
        returns (bool)
    {
        if (_getAccessLevel(accessMappingTarget, settingsCaller) < MANAGER) {
            return false;
        } else {
            return true;
        }
    }    

    function getPaymentsAccess(address accessMappingTarget, address paymentsCaller)
        external
        view
        returns (bool)
    {
        if (_getAccessLevel(accessMappingTarget, settingsCaller) < ADMIN) {
            return false;
        } else {
            return true;
        }
    }        
}