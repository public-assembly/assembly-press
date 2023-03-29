// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControlRegistry} from "../../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Press} from "../../core/interfaces/IERC721Press.sol";

/**
* @title HybridAccess
* @notice Facilitates role based access control for admin/manager roles, and erc721 ownership based access for curator role
* @author Max Bochman
*/
contract HybridAccess is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
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
    /// @notice Invalid role being set
    error RoleDoesntExist();    
    /// @notice Initialization coming from unauthorized contract
    error UnauthorizedInitializer();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when curationGate address updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param newGate new address set for curationGate
    event CuratorGateUpdated(
        address targetPress,
        address sender,
        address newGate
    );            

    /// @notice Event emitted when a new admin/manager/no_role role is granted
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param account account receiving new role
    /// @param role role being granted
    event RoleGranted(
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
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "HybridAccess";

    // Role constants
    uint8 constant ADMIN = 3;
    uint8 constant MANAGER = 2;
    uint8 constant NO_ROLE = 0;    

    // Press contract to ERC721 being used to gate curator functionality
    mapping(address => address) public curatorGateInfo;

    // Press contract to account to role for determining admin/manager functionality
    mapping(address => mapping(address => uint8)) public roleInfo;

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

        // Ensure that only the expected CurationLogic contract is calling this function
        if (msg.sender != address(IERC721Press(targetPress).getLogic())) {
            revert UnauthorizedInitializer();
        }

        // abi.decode initial gate information set on access control initialization
        (address curatorGate, RoleDetails[] memory initialRoles) = abi.decode(data, (address, RoleDetails[]));

        // call internal grant roles function 
        _grantRoles(targetPress, initialRoles);

        // check if curatorGate was set to non zero address and update its value + emit event if it was
        if (curatorGate != address(0)) {
            curatorGateInfo[targetPress] = curatorGate;
            emit CuratorGateUpdated(targetPress, msg.sender, curatorGate);
        }
    }

    /// @notice Grants new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function grantRoles(address targetPress, RoleDetails[] memory roleDetails) 
        onlyAdmin(targetPress) 
        external
    {
        _grantRoles(targetPress, roleDetails);
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

    /// @notice internal grant new roles for given press
    /// @param targetPress target Press index
    /// @param roleDetails array of roleDetails structs
    function _grantRoles(address targetPress, RoleDetails[] memory roleDetails) internal {
        // grant roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being granted is a valid role
            if (roleDetails[i].role != ADMIN && roleDetails[i].role != MANAGER) {
                revert RoleDoesntExist();
            }
            // give role to account
            roleInfo[targetPress][roleDetails[i].account] = roleDetails[i].role;

            emit RoleGranted({
                targetPress: targetPress,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }    
    }        

    /// @notice Changes the address of the curatorGate in use for a given targetPress
    /// @param targetPress target Press index
    /// @param newCuratorGate new address for the curatorGate
    function setCuratorGate(address targetPress, address newCuratorGate) external onlyAdmin(targetPress) {
        curatorGateInfo[targetPress] = newCuratorGate;

        emit CuratorGateUpdated({
            targetPress: targetPress,
            sender: msg.sender,
            newGate: newCuratorGate
        });
    }

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address addressToGetAccessFor)
        external
        view
        returns (uint256)
    {
        // cache role for given target address
        uint8 role = roleInfo[accessMappingTarget][addressToGetAccessFor];

        // first check if address has admin/manager role, return that role if it does
        // if no admin/manager role, check if address has a balance of > 0 of the curationGate contract, return 1 if it does
        // return 0 if all of the above is false
        if (role != NO_ROLE) {
            return role;
        } else if (IERC721(curatorGateInfo[accessMappingTarget]).balanceOf(addressToGetAccessFor) != 0) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice returns mintPrice for a given Press + account + mintQuantity
    /// @dev called via the logic contract that has been set for a given Press
    function getMintPrice(address accessMappingTarget, address addressToGetAccessFor, uint256 mintQuantity)
        external
        view
        returns (uint256)
    {
        // always returns zero to hardcode no fee necessary
        return 0;
    }        
}