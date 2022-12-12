// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ERC721OwnerInterface {
  function ownerOf(uint256 tokenid) external returns (address);
  function isApprovedForAll(address owner, address operator) external returns (bool);
  function burn(uint256 tokenId) external;
}