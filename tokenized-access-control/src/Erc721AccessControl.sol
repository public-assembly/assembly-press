// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract Erc721AccessControl is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // ERRORS 
    //////////////////////////////////////////////////
    
    error Access_OnlyAdmin();

    //////////////////////////////////////////////////
    // EVENTS 
    //////////////////////////////////////////////////

    /// @notice Event for updated curatorAccess
    event CuratorAccessUpdated(
        address indexed target,
        IERC721Upgradeable curatorAccess
    );    

    /// @notice Event for updated managerAccess
    event ManagerAccessUpdated(
        address indexed target,
        IERC721Upgradeable managerAccess
    );        

    /// @notice Event for updated adminAccess
    event AdminAccessUpdated(
        address indexed target,
        IERC721Upgradeable adminAccess
    );       

    /// @notice Event for updated AccessLevelInfo
    event AllAccessUpdated(
        address indexed target,
        IERC721Upgradeable curatorAccess,
        IERC721Upgradeable managerAccess,
        IERC721Upgradeable adminAccess
    );           

    /// @notice Event for a new access control initialized
    /// @dev admin function indexer feedback
    event AccessControlInitialized(
        address indexed target,
        IERC721Upgradeable curatorAccess,
        IERC721Upgradeable managerAccess,
        IERC721Upgradeable adminAccess
    );    

    //////////////////////////////////////////////////
    // VARIABLES 
    //////////////////////////////////////////////////

    // struct that contains addresses which gate different levels of access to curation contract
    struct AccessLevelInfo {
        IERC721Upgradeable curatorAccess;
        IERC721Upgradeable managerAccess;
        IERC721Upgradeable adminAccess;
    }

    /// @notice access information mapping storage
    /// @dev curation contract => AccessLevelInfo struct
    mapping(address => AccessLevelInfo) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    //////////////////////////////////////////////////

    /// @dev updates ERC721 address used to define curator access
    function updateCurator(
        address target,
        IERC721Upgradeable newCuratorAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].curatorAccess = newCuratorAccess; 

        emit CuratorAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess
        });
    }

    /// @dev updates ERC721 address used to define manager access
    function updateManagerAccess(
        address target,
        IERC721Upgradeable newManagerAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].managerAccess = newManagerAccess; 

        emit ManagerAccessUpdated({
            target: target,
            managerAccess: newManagerAccess
        });
    }    

    /// @dev updates ERC721 address used to define admin access
    function updateAdminAccess(
        address target,
        IERC721Upgradeable newAdminAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].adminAccess = newAdminAccess; 

        emit AdminAccessUpdated({
            target: target,
            adminAccess: newAdminAccess
        });
    }      

    /// @dev updates ERC721 address used to define curator, manager, and admin access
    function updateAllAccess(
        address target,
        IERC721Upgradeable newCuratorAccess,
        IERC721Upgradeable newManagerAccess,
        IERC721Upgradeable newAdminAccess
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }
        
        accessMapping[target].curatorAccess = newCuratorAccess; 
        accessMapping[target].managerAccess = newManagerAccess; 
        accessMapping[target].adminAccess = newAdminAccess; 

        emit AllAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess,
            managerAccess: newManagerAccess,
            adminAccess: newAdminAccess
        });
    }              

    /// @dev called by other contracts initiating access control
    ///     initializes mapping of contract getting access control => erc721 addresses used for access control of different roles
    function initializeWithData(bytes memory data) external {
        // data format: curatorAccess, managerAccess, adminAccess
        (
            IERC721Upgradeable curatorAccess,
            IERC721Upgradeable managerAccess,
            IERC721Upgradeable adminAccess
        ) = abi.decode(data, (IERC721Upgradeable, IERC721Upgradeable, IERC721Upgradeable));

        accessMapping[msg.sender] = AccessLevelInfo({
            curatorAccess: curatorAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess
        });

        emit AccessControlInitialized({
            target: msg.sender,
            curatorAccess: curatorAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess
        });
    }

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS 
    //////////////////////////////////////////////////

    /// @dev returns access level of a user address calling function
    ///     via the external contract that has initialized access control
    function getAccessLevel(address addressToCheckLevel)
        external
        view
        returns (uint256)
    {
        address target = msg.sender;

        AccessLevelInfo memory info = accessMapping[target];

        if (info.adminAccess.balanceOf(addressToCheckLevel) != 0) {
            return 3;
        } 

        if (info.managerAccess.balanceOf(addressToCheckLevel) != 0) {
            return 2;
        } 

        if (info.curatorAccess.balanceOf(addressToCheckLevel) != 0) {
            return 1;
        }         

        return 0;
    }

    /// @dev returns the addresses being used for access control
    function getAccessInfo(address addressToCheck) 
        external 
        view 
        returns (AccessLevelInfo memory)
    {
        return accessMapping[addressToCheck];
    }    

    /// @dev returns the erc721 address being used for curator access control
    function getCuratorInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].curatorAccess;
    }    

    /// @dev returns the erc721 address being used for manager access control
    function getManagerInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].managerAccess;
    }        

    /// @dev returns the erc721 address being used for admin access control
    function getAdminInfo(address addressToCheck) 
        external 
        view 
        returns (IERC721Upgradeable)
    {
        return accessMapping[addressToCheck].adminAccess;
    }        
}