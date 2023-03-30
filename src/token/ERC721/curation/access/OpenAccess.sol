// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IAccessControlRegistry} from "../../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

contract OpenAccess is IAccessControlRegistry {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    string public constant name = "OpenAccess";

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /// @notice initializes mapping of access control
    /// @dev contract initializing access control => admin address
    /// @dev called by other contracts initiating access control
    function initializeWithData(address sender, bytes memory data) external {}

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