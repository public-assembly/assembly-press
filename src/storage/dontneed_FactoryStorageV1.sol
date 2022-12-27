
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IPress} from "./interfaces/IPress.sol";

/**
 @notice 
 @author 
 */
contract FactoryStorageV1 {

    /* SHOULDNT ACTUALLY STORE THIS? SHOULD JUST BE A REGISTRY LOOKUP?
    /// @notice  press -> {metadataRenderer, mintingLogic, accessControl}
    mapping(address => IPress.PressConfig) public pressInfo;
    */

    // /// @notice Storage gap
    // uint256[49] __gap;
}