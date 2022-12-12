// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";

interface IERC721DropMinter {
    
    function adminMint(address recipient, uint256 quantity) external returns (uint256);

    function hasRole(bytes32, address) external returns (bool);

    function isAdmin(address) external returns (bool);

    function saleDetails(address) external returns (IERC721Drop.SaleDetails memory);
}