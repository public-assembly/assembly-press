// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721DropMinterInterface {
  function adminMint(address recipient, uint256 quantity) external returns (uint256);
}