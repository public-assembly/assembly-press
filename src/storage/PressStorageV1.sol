
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IPress} from "../interfaces/IPress.sol";

/**
 @notice
 @author 
 */
contract PressStorageV1 {

    /// @notice PressConfig for Press contract storage
    IPress.PressConfig public pressConfig;      

    /// @notice PrimarySaleFee for Press contract storage
    IPress.PrimarySaleFee public primarySaleFeeConfig;

}