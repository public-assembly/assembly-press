// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressContractLogic {  
    
    // Initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can access mintnew functionality for a given Press + recepients + quantity combination
    function canMintNew(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (bool);    
    /// @notice checks if a certain address can set ownership of a given Press
    function canSetOwner(address targetPress, address transferCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintNewPrice(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}