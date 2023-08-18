// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IPressTypesV1} from "../types/IPressTypesV1.sol";

// TODO: Check if missing UUPS storage gap?
// TODO: Also just do more research + get feedback on storage layout in general

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
    address public feeRouter;    
    mapping(uint256 => address) public fundsRecipientOverrides;
    IPressTypesV1.Settings public settings;
}
