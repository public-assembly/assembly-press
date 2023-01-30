// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155PressTokenLogic {  
    
    // Initialize function
    /// @notice initializes logic file for a given tokenId + Press with arbitrary data
    function initializeWithData(uint256 tokenId, bytes memory initData) external;    

    // Access control functions
    /// @notice checks if a certain address can edit metadata post metadata initialization for a given Press + tokenId
    function canEditMetadata(address targetPress, uint256 tokenId, address editCaller) external view returns (bool);        
    /// @notice checks if a certain address can update the Config struct on a given tokenId for a given Press 
    function canUpdateConfig(address targetPress, uint256 tokenId, address updateCaller) external view returns (bool);
    /// @notice checks if a certain address can access mint functionality for a given tokenId for a given Press + recipient + quantity combination
    function canMintExisting(address targetPress, address mintCaller, uint256 tokenId, address[] memory recipients, uint256 quantity) external view returns (bool);
    /// @notice checks if a certain address can access batchMint functionality for a given Press + tokenIds + recipient + quantities combination
    function canBatchMintExisting(address targetPress, address mintCaller, uint256[] memory tokenIds, address recipient, uint256[] memory quantities) external view returns (bool);    
    /// @notice checks if a certain address can call the withdraw function for a given tokenId for a given Press
    function canWithdraw(address targetPress, uint256 tokenId, address withdrawCaller) external view returns (bool);
    /// @notice checks if a certain address can call the burn function for a given tokenId for a given Press
    function canBurn(address targetPress, uint256 tokenId, uint256 quantity, address burnCaller) external view returns (bool);    

    // Informative view functions
    /// @notice checks if a given Press has been initialized    
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool);        
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintExistingPrice(address targetPress, uint256 tokenId, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   
}