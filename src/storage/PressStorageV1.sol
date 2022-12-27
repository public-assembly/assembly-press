
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IPress} from "./interfaces/IPress.sol";

/**
 @notice
 @author 
 */
contract PublisherStorage {

    IPress.PressConfig public pressConfig;      

    address public owner;
}