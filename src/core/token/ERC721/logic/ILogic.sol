// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILogic {
    
    // Basic info
    function name() external view returns (string memory);    

    // Write functions
    function initializeWithData(address, bytes memory initData) external;

    // Access control functions
    /// @notice checks if a certain address get access mint functionality for a given Press + quantity combination
    function getMintAccess(address targetPress, address mintCaller, uint256 mintQuantity) external view returns (bool);
    /// @notice checks if a certain address get call the burn function for a given Press
    function getBurnAccess(address targetPress, address burnCaller, uint256 tokenId) external view returns (bool);     
    /// @notice checks if a certain address get call the sort function for a given Press
    function getSortAccess(address targetPress, address sortCaller) external view returns (bool);     
    /// @notice checks if a certain address can update the logic or renderer contract for a given Press
    function getSettingsAccess(address targetPress, address settingsCaller) external view returns (bool);      
    /// @notice checks if a certain address get edit metadata post metadata initialization for a given token for a given Press
    function getMetadataAccess(address targetPress, address metadataCaller, uint256 tokenId) external view returns (bool);        
    /// @notice checks if a certain address get access specific functionality when database is paused
    function getPauseAccess(address targetPress, address txnCaller) external view returns (bool);
    /// @notice checks if a certain address get edit payment settings for a given Press
    function getPaymentsAccess(address targetPress, address txnCaller) external view returns (bool);       

    // Other Getters
    /// @notice calculates totalMintPrice for a given Press, mintCaller, and mintQuantity
    function getMintPrice(address targetPress, address mintCaller, uint64 mintQuantity) external view returns (uint256);        
}