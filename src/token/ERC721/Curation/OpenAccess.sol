// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControlRegistry} from "../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

contract OpenAccess is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////

    /// @notice Error for trying to update access
    error Access_Cannot_Be_Updated();

    //////////////////////////////////////////////////
    // VARIABLES
    //////////////////////////////////////////////////

    string public constant name = "OpenAccess";

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    /// @dev data format: admin
    function initializeWithData(bytes memory data) external {}

    /// @notice updates strategy of already initialized access control mapping
    /// @dev will always revert since this access control scheme cannotbe updated
    function updateWithData(bytes memory data) external {
        revert Access_Cannot_Be_Updated();
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
        return 1;
    }
}