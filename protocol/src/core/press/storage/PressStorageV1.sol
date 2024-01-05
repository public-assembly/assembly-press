// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IPressTypesV1} from "../types/IPressTypesV1.sol";

// TODO: Research + get feedback on storage layout in general
//      particularly storage struct buckets
// TODO: missing UUPS storage gap

contract PressStorageV1 {
    ////////////////////////////////////////////////////////////
    // DATA
    ////////////////////////////////////////////////////////////

    /**
     * @notice Pointer to encoded data stored at press level
     */
    address public pressData;

    /**
     * @notice ID => Pointer to encoded data
     * @dev Can contain blank/burned storage
     */
    mapping(uint256 => address) public tokenData;

    ////////////////////////////////////////////////////////////
    // SETTINGS
    ////////////////////////////////////////////////////////////

    address public router;
    string public name;
    IPressTypesV1.Settings public settings;
    mapping(uint256 => address) public fundsRecipientOverrides;
}
