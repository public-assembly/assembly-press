// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract ERC20MinBalAccessControl is IAccessControlRegistry {
    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error for only admin access
    error Access_OnlyAdmin();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event for updated curatorAccess
    event CuratorAccessUpdated(
        address indexed target,
        IERC20 curatorAccess,
        uint256 curatorMinimumBalance
    );

    /// @notice Event for updated managerAccess
    event ManagerAccessUpdated(
        address indexed target,
        IERC20 managerAccess,
        uint256 managerMinimumBalance
    );

    /// @notice Event for updated adminAccess
    event AdminAccessUpdated(
        address indexed target,
        IERC20 adminAccess,
        uint256 adminMinimumBalance
    );

    /// @notice Event for updated AccessLevelInfo
    event AllAccessUpdated(
        address indexed target,
        IERC20 curatorAccess,
        IERC20 managerAccess,
        IERC20 adminAccess,
        uint256 curatorMinimumBalance,
        uint256 managerMinimumBalance,
        uint256 adminMinimumBalance
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
        uint256 curatorMinimumBalance;
        uint256 managerMinimumBalance;
        uint256 adminMinimumBalance;
    }

    /// @notice access information mapping storage
    /// @dev curation contract => AccessLevelInfo struct
    mapping(address => AccessLevelInfo) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice updates ERC20 address used to define curator access
    function updateCuratorAccess(
        address target,
        IERC20 newCuratorAccess,
        uint256 newMinBalance
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].curatorAccess = newCuratorAccess;
        accessMapping[target].curatorMinimumBalance = newMinBalance;

        emit CuratorAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess,
            curatorMinimumBalance: newMinBalance
        });
    }

    /// @notice updates ERC20 address used to define manager access
    function updateManagerAccess(
        address target,
        IERC20 newManagerAccess,
        uint256 newMinBalance
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].managerAccess = newManagerAccess;
        accessMapping[target].managerMinimumBalance = newMinBalance;

        emit ManagerAccessUpdated({
            target: target,
            managerAccess: newManagerAccess,
            managerMinimumBalance: newMinBalance
        });
    }

    /// @notice updates ERC20 address used to define admin access
    function updateAdminAccess(
        address target,
        IERC20 newAdminAccess,
        uint256 newMinBalance
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].adminAccess = newAdminAccess;
        accessMapping[target].adminMinimumBalance = newMinBalance;

        emit AdminAccessUpdated({
            target: target,
            adminAccess: newAdminAccess,
            adminMinimumBalance: newMinBalance
        });
    }

    /// @notice updates ERC20 address used to define curator, manager, and admin access
    function updateAllAccess(
        address target,
        IERC20 newCuratorAccess,
        IERC20 newManagerAccess,
        IERC20 newAdminAccess,
        uint256 newCuratorMinBal,
        uint256 newManagerMinBal,
        uint256 newAdminMinBal
    ) external {
        if (accessMapping[target].adminAccess.balanceOf(msg.sender) == 0) {
            revert Access_OnlyAdmin();
        }

        accessMapping[target].curatorAccess = newCuratorAccess;
        accessMapping[target].managerAccess = newManagerAccess;
        accessMapping[target].adminAccess = newAdminAccess;
        accessMapping[target].curatorMinimumBalance = newCuratorMinBal;
        accessMapping[target].managerMinimumBalance = newManagerMinBal;
        accessMapping[target].adminMinimumBalance = newAdminMinBal;

        emit AllAccessUpdated({
            target: target,
            curatorAccess: newCuratorAccess,
            managerAccess: newManagerAccess,
            adminAccess: newAdminAccess,
            curatorMinimumBalance: newCuratorMinBal,
            managerMinimumBalance: newManagerMinBal,
            adminMinimumBalance: newAdminMinBal
        });
    }

    /// @notice initializes mapping of token roles
    /// @dev contract getting access control => ERC20 addresses used for access control of different roles
    /// @dev called by other contracts initiating access control
    /// @dev data format: curatorAccess, managerAccess, adminAccess
    function initializeWithData(bytes memory data) external {
        (IERC20 curatorAccess, IERC20 managerAccess, IERC20 adminAccess) = abi
            .decode(data, (IERC20, IERC20, IERC20));

        accessMapping[msg.sender] = AccessLevelInfo({
            curatorAccess: curatorAccess,
            managerAccess: managerAccess,
            adminAccess: adminAccess,
            curatorMinimumBalance: 1,
            managerMinimumBalance: 1,
            adminMinimumBalance: 1
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

        if (
            info.adminAccess.balanceOf(addressToCheckLevel) >
            info.adminMinimumBalance - 1
        ) {
            return 3;
        }

        if (
            info.managerAccess.balanceOf(addressToCheckLevel) >
            info.managerMinimumBalance - 1
        ) {
            return 2;
        }

        if (
            info.curatorAccess.balanceOf(addressToCheckLevel) >
            info.curatorMinimumBalance - 1
        ) {
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

    /// @notice returns the ERC20 address being used for curator access control
    function getCuratorInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].curatorAccess;
    }

    /// @notice returns the ERC20 address being used for manager access control
    function getManagerInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].managerAccess;
    }

    /// @notice returns the ERC20 address being used for admin access control
    function getAdminInfo(address addressToCheck)
        external
        view
        returns (IERC20)
    {
        return accessMapping[addressToCheck].adminAccess;
    }
}
