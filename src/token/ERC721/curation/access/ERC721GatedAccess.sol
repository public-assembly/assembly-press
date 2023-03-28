// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControlRegistry} from "../../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC721Press} from "../../core/interfaces/IERC721Press.sol";

contract ERC721GatedAccess is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    error RequiresCuratorGate();
    error RequiresAdminGate();


    error RequiresAdmin();
    error RequiresHigherRole();
    error RoleDoesntExist();    

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    event GatesInitialized(
        address targetPress,
        address sender,
        address curationGate,
        address adminGate
    );    

    event CuratorGateChanged(
        address targetPress,
        address sender,
        address newGate
    );            

    event AdminGateChanged(
        address targetPress,
        address sender,
        address newGate
    );                

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "ERC721GatedAccess";

    // Curation contract to ERC721 used for gating
    mapping(address => IERC721) curatorGateInfo;
    mapping(address => IERC721) adminGateInfo;

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
        return adminGateInfo[targetPress].balanceOf(account) != 0 ? true : false;
    }
    

    /// @notice isAdmin getter for a target index
    /// @param targetPress target Press
    /// @param account account to check
    function _isAdminOrCurator(address targetPress, address account)
        internal
        view
        returns (bool)
    {
        // Return true/false depending on whether account is an admin or Curator
        return curatorGateInfo[targetPress].balanceOf(account) != 0
                || adminGateInfo[targetPress].balanceOf(account) != 0 ? true : false;
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
    /// @dev only allows approved Curators or admins of platform index (from msg.sender)
    modifier onlyAdminOrCurator(address targetPress) {
        if (!_isAdminOrCurator(targetPress, msg.sender)) {
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
        require(msg.sender == address(IERC721Press(targetPress).getLogic()), "Unauthorized caller");

        // abi.decode initial gate information set on access control initialization
        (IERC721 curatorGate, IERC721 adminGate) = abi.decode(data, (IERC721, IERC721));

        curatorGateInfo[targetPress] = curatorGate;
        adminGateInfo[targetPress] = adminGate;
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
        // check if account owns gate tokens
        if (adminGateInfo[accessMappingTarget].balanceOf(addressToGetAccessFor) != 0) {
            return 3;
        } else if (curatorGateInfo[accessMappingTarget].balanceOf(addressToGetAccessFor) != 0) {
            return 1;
        } else {
            return 0;
        }
    }

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getMintPrice(address accessMappingTarget, address addressToGetAccessFor, uint256 mintQuantity)
        external
        view
        returns (uint256)
    {
        // always returns zero to hardcode no fee necessary
        return 0;
    }        
}