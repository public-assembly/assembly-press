// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { ICuration } from "./ICuration.sol";
import { IAccessControlRegistry } from "onchain/interfaces/IAccessControlRegistry.sol";

/**
 @notice Curation storage variables contract.
 */
abstract contract CurationStorageV1 is ICuration {
    /// @notice Address of the accessControl contract
    IAccessControlRegistry public accessControl;    

    /// Stores virtual mapping array length parameters
    /// @notice Array total size (total size)
    uint40 public numAdded;

    /// @notice Array active size = numAdded - numRemoved
    /// @dev Blank entries are retained within array
    uint40 public numRemoved;

    /// @notice If curation is paused by the owner
    bool public isPaused;

    /// @notice timestamp that the curation is frozen at (if never, frozen = 0)
    uint256 public frozenAt;

    /// @notice Listing id => Listing struct mapping, listing IDs are 0 => upwards
    /// @dev Can contain blank entries (not garbage compacted!)
    mapping(uint256 => Listing) public idToListing;

    /// @notice Storage gap
    uint256[49] __gap;
}