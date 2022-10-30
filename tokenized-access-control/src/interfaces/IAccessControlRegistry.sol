// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControlRegistry {
    
    function initializeWithData(bytes memory initData) external;
    
    function getAccessLevel(address) external view returns (uint256);
    
}