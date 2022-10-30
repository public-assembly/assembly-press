// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract Erc20AccessControl is IAccessControlRegistry {
    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error for only admin access
    error Access_OnlyAdmin();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event for updated curatorAccess
    event CuratorAccessUpdated(address indexed target, IERC20 curatorAccess);

    /// @notice Event for updated managerAccess
    event ManagerAccessUpdated(address indexed target, IERC20 managerAccess);

    /// @notice Event for updated adminAccess
    event AdminAccessUpdated(address indexed target, IERC20 adminAccess);

    /// @notice Event for updated AccessLevelInfo
    event AllAccessUpdated(
        address indexed target,
        IERC20 curatorAccess,
        IERC20 managerAccess,
        IERC20 adminAccess
    );

    /// @notice Event for a new access control initialized
    /// @dev admin function indexer feedback
    event AccessControlInitialized(
        address indexed target,
        IERC20 curatorAccess,
        IERC20 managerAccess,
        IERC20 adminAccess
    );

    //////////////////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////////////////

    /// @notice struct that contains addresses which gate different levels of access to curation contract
    struct AccessLevelInfo {
        IERC20 curatorAccess;
        IERC20 managerAccess;
        IERC20 adminAccess;
    }

    /// @notice access information mapping storage
    /// @dev curation contract => AccessLevelInfo struct
    mapping(address => AccessLevelInfo) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice updates ERC721 address used to define curator access
    function updateCurator(address target, IERC20 newCuratorAccess) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].curatorAccess = newCuratorAccess;

        emit CuratorAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess
        });
    }

    /// @notice updates ERC721 address used to define manager access
    function updateManagerAccess(address target, IERC20 newManagerAccess)
        external
    {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].managerAccess = newManagerAccess;

        emit ManagerAccessUpdated({
            target: target,
            managerAccess: newManagerAccess
        });
    }

    /// @notice updates ERC721 address used to define admin access
    function updateAdminAccess(address target, IERC20 newAdminAccess) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].adminAccess = newAdminAccess;

        emit AdminAccessUpdated({target: target, adminAccess: newAdminAccess});
    }

    /// @notice updates ERC721 address used to define curator, manager, and admin access
    function updateAllAccess(
        address target,
        IERC20 newCuratorAccess,
        IERC20 newManagerAccess,
        IERC20 newAdminAccess
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

    /// @notice initializes mapping of token roles
    /// @dev contract getting access control => erc721 addresses used for access control of different roles
    /// @dev called by other contracts initiating access control
    /// @dev data format: curatorAccess, managerAccess, adminAccess
    function initializeWithData(bytes memory data) external {
        (IERC20 curatorAccess, IERC20 managerAccess, IERC20 adminAccess) = abi
            .decode(data, (IERC20, IERC20, IERC20));

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

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
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

    /// @notice returns the addresses being used for access control
    function getAccessInfo(address addressToCheck)
        external
        view
        returns (AccessLevelInfo memory)
    {
        return accessMapping[addressToCheck];
    }

    /// @notice returns the erc721 address being used for curator access control
    function getCuratorInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].curatorAccess;
    }

    /// @notice returns the erc721 address being used for manager access control
    function getManagerInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].managerAccess;
    }

    /// @notice returns the erc721 address being used for admin access control
    function getAdminInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].adminAccess;
    }
}
