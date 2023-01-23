// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155Press} from "../interfaces/IERC1155Press.sol";

contract ERC1155PressStorageV1 {
    
    /// @notice Configuration for Press contract storage. stored at tokenId level
    mapping(uint256 => IERC1155Press.Configuration) public config;      
    /// @notice PrimarySaleFee for Press contract storage. stored at tokenId level
    mapping(uint256 => IERC1155Press.PrimarySaleFee) public primarySaleFeeDetails;

    /// @notice contract level logic logic storage
    address public contractLevelLogic;

}