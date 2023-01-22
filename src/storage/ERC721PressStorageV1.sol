// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155Press} from "../interfaces/IERC1155Press.sol";

contract ERC721PressStorageV1 {
    /// @notice Configuration for Press contract storage
    IERC1155Press.Configuration public config;      

    /// @notice PrimarySaleFee for Press contract storage
    IERC1155Press.PrimarySaleFee public primarySaleFeeDetails;
}