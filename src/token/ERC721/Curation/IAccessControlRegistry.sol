// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAccessControlRegistry {
    
    function name() external view returns (string memory);    
    
    function initializeWithData(address sender, bytes memory initData) external;

    function updateWithData(bytes memory updateData) external;
    
    function getAccessLevel(address, address) external view returns (uint256);
    
}