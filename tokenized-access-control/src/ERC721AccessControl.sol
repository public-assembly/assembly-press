// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract ERC721AccessControl is IAccessControlRegistry {
    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error for only admin access
    error Access_OnlyAdmin();
    error AccessRole_NotInitialized();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event for updated userAccess
    event UserAccessUpdated(
        address indexed accessMappingTarget,
        address userAccess
    );

    /// @notice Event for updated managerAccess
    event ManagerAccessUpdated(
        address indexed accessMappingTarget,
        address managerAccess
    );

    /// @notice Event for updated adminAccess
    event AdminAccessUpdated(
        address indexed accessMappingTarget,
        address adminAccess
    );

    /// @notice Event for updated AccessLevelInfo
    event AllAccessUpdated(
        address indexed accessMappingTarget,
        address userAccess,
        address managerAccess,
        address adminAccess
    );

    /// @notice Event for a new access control initialized
    /// @dev admin function indexer feedback
    event AccessControlInitialized(
        address indexed accessMappingTarget,
        address userAccess,
        address managerAccess,
        address adminAccess
    );

    //////////////////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////////////////

    /// @notice struct that contains addresses which gate different levels of access to initialized contracts
    struct AccessLevelInfo {
        IERC721Upgradeable userAccess;
        IERC721Upgradeable managerAccess;
        IERC721Upgradeable adminAccess;
    }

    string public constant name = "ERC721AccessControl";

    /// @notice access information mapping storage
    /// @dev initialized contract => AccessLevelInfo struct
    mapping(address => AccessLevelInfo) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice updates ERC721 address used to define user access
    function updateUserAccess(address accessMappingTarget, address newUserAccess)
        external
    {
        if (accessMapping[accessMappingTarget].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[accessMappingTarget].userAccess = IERC721Upgradeable(newUserAccess);

        emit UserAccessUpdated({
            accessMappingTarget: accessMappingTarget,
            userAccess: newUserAccess
        });
    }

    /// @notice updates ERC721 address used to define manager access
    function updateManagerAccess(address accessMappingTarget, address newManagerAccess) 
        external 
    {
        if (accessMapping[accessMappingTarget].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[accessMappingTarget].managerAccess = IERC721Upgradeable(newManagerAccess);

        emit ManagerAccessUpdated({
            accessMappingTarget: accessMappingTarget,
            managerAccess: newManagerAccess
        });
    }

    /// @notice updates ERC721 address used to define admin access
    function updateAdminAccess(address accessMappingTarget, address newAdminAccess) 
        external 
    {
        if (accessMapping[accessMappingTarget].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[accessMappingTarget].adminAccess = IERC721Upgradeable(newAdminAccess);

        emit AdminAccessUpdated({
            accessMappingTarget: accessMappingTarget, 
            adminAccess: newAdminAccess
        });
    }

    /// @notice updates ERC721 address used to define user, manager, and admin access
    function updateAllAccess(
        address accessMappingTarget,
        address newUserAccess,
        address newManagerAccess,
        address newAdminAccess
    ) external {
        if (accessMapping[accessMappingTarget].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[accessMappingTarget].userAccess = IERC721Upgradeable(newUserAccess);
        accessMapping[accessMappingTarget].managerAccess = IERC721Upgradeable(newManagerAccess);
        accessMapping[accessMappingTarget].adminAccess = IERC721Upgradeable(newAdminAccess);

        emit AllAccessUpdated({
            accessMappingTarget: accessMappingTarget,
            userAccess: newUserAccess,
            managerAccess: newManagerAccess,
            adminAccess: newAdminAccess
        });
    }

    /// @notice initializes mapping of token roles
    /// @dev contract getting access control => erc721 addresses used for access control of different roles
    /// @dev called by other contracts initiating access control
    /// @dev data format: userAccess, managerAccess, adminAccess
    function initializeWithData(bytes memory data) external {
        (
            address userAccess,
            address managerAccess,
            address adminAccess
        ) = abi.decode(
                data,
                (address, address, address)
            );

        accessMapping[msg.sender] = AccessLevelInfo({
            userAccess: IERC721Upgradeable(userAccess),
            managerAccess: IERC721Upgradeable(managerAccess),
            adminAccess: IERC721Upgradeable(adminAccess)
        });

        emit AccessControlInitialized({
            accessMappingTarget: msg.sender,
            userAccess: userAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess
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

        AccessLevelInfo memory info = accessMapping[accessMappingTarget];

        if (address(info.adminAccess) != address(0)) {
            if (info.adminAccess.balanceOf(addressToGetAccessFor) != 0) {
                return 3;
            }        
        }

        if (address(info.managerAccess) != address(0)) {
            if (info.managerAccess.balanceOf(addressToGetAccessFor) != 0) {
                return 2;
            }
        }

        if (address(info.userAccess) != address(0)) {
            if (info.userAccess.balanceOf(addressToGetAccessFor) != 0) {
                return 1;
            }
        }

        return 0;
    }

    /// @notice returns the addresses being used for access control by a given contract
    function getAccessInfo(address accessMappingTarget)
        external
        view
        returns (AccessLevelInfo memory)
    {
        return accessMapping[accessMappingTarget];
    }

    /// @notice returns the erc721 address being used for user access control by a given contract
    function getUserInfo(address accessMappingTarget)
        external
        view
        returns (IERC721Upgradeable)
    {
        return accessMapping[accessMappingTarget].userAccess;
    }

    /// @notice returns the erc721 address being used for manager access control by a given contract
    function getManagerInfo(address accessMappingTarget)
        external
        view
        returns (IERC721Upgradeable)
    {
        return accessMapping[accessMappingTarget].managerAccess;
    }

    /// @notice returns the erc721 address being used for admin access control by a given contract
    function getAdminInfo(address accessMappingTarget)
        external
        view
        returns (IERC721Upgradeable)
    {
        return accessMapping[accessMappingTarget].adminAccess;
    }
}
