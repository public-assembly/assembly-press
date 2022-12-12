// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAccessControlRegistry} from "./interfaces/IAccessControlRegistry.sol";

contract OnlyAdminAccessControl is IAccessControlRegistry {
    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error for only admin access
    error Access_OnlyAdmin();
    error AccessRole_NotInitialized();

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event for updated admin
    event AdminUpdated(
        address indexed accessMappingTarget,
        address newAdmin
    );

    /// @notice Event for a new access control initialized
    /// @dev admin function indexer feedback
    event AccessControlInitialized(
        address indexed accessMappingTarget,
        address admin
    );

    //////////////////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////////////////

    string public constant name = "OnlyAdminAccessControl";

    /// @notice access information mapping storage
    /// @dev curation contract => admin address
    mapping(address => address) public accessMapping;

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice updates admin address
    function updateAdmin(address accessMappingTarget, address newAdmin) external {
        if (accessMapping[accessMappingTarget] != msg.sender) {
            revert Access_OnlyAdmin();
        }

        accessMapping[accessMappingTarget] = newAdmin;

        emit AdminUpdated({accessMappingTarget: accessMappingTarget, newAdmin: newAdmin});
    }

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    /// @dev data format: admin
    function initializeWithData(bytes memory data) external {
        (address admin) = abi.decode(data, (address));

        require(admin != address(0), "admin cannot be zero address");

        accessMapping[msg.sender] = admin;

        emit AccessControlInitialized({
            accessMappingTarget: msg.sender,
            admin: admin
        });
    }

    //////////////////////////////////////////////////
    // VIEW FUNCTIONS›
    //////////////////////////////////////////////////

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address addressToGetAccessFor)
        external
        view
        returns (uint256)
    {

        if (accessMapping[accessMappingTarget] == addressToGetAccessFor) {
            return 3;
        }

        return 0;
    }

    /// @notice returns the address declared as admin by a given contract
    function getAdminInfo(address accessMappingTarget)
        external
        view
        returns (address)
    {
        return accessMapping[accessMappingTarget];
    }
}
