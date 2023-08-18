// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IChannelTypesV1} from "../types/IChannelTypesV1.sol";

// TODO: Check if missing UUPS storage gap?
// TODO: Also just do more research + get feedback on storage layout in general

contract ChannelStorageV1 {

    ////////////////////////////////////////////////////////////
    // SETTINGS
    ////////////////////////////////////////////////////////////    
    
    address public river;
    IChannelTypesV1.Settings public settings;
    address public feeRouter;
    mapping(uint256 => address) public fundsRecipientOverrides;
    string public name;

    ////////////////////////////////////////////////////////////
    // DATA
    ////////////////////////////////////////////////////////////    

    /**
     * @notice Pointer to encoded data stored at channel level
     */    
    address public channelData;

    /**
     * @notice ID => Pointer to encoded data
     * @dev Can contain blank/burned storage
     */
    mapping(uint256 => address) public tokenData;
}
