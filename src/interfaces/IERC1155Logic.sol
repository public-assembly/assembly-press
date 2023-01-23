// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ILogic {  

    // initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    // access control functions
    /// @notice checks if a certain address can update the Config struct on a given tokenId for a given Press 
    function canUpdatePressConfig(address targetPress, uint256 tokenId, address updateCaller) external view returns (bool);

    /// @notice checks if a certain address can access mint functionality for a given tokenId for a given Press + quantity combination
    function canMintExisting(address targetPress, uint256 tokenId, uint64 mintQuantity, address mintCaller) external view returns (bool);

    /// @notice checks if a certain address can edit metadata post metadata initialization for a given tokenId for a given Press
    function canEditMetadata(address targetPress, uint256 tokenId, address editCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the withdraw function for a given tokenId for a given Press
    function canWithdraw(address targetPress, uint256 tokenId, address withdrawCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the burn function for a given tokenId for a given Press
    function canBurn(address targetPress, uint256 tokenId, address burnCaller) external view returns (bool);    
    /// @notice checks if a certain address can upgrade the underlying implementation for a given tokenId for a given Press
    function canUpgrade(address targetPress, uint256 tokenId, address upgradeCaller) external view returns (bool);
    /// @notice checks if a certain address can transfer ownership of a given tokenId for a given Press
    function canTransfer(address targetPress, uint256 tokenId, address transferCaller) external view returns (bool);    
    
    // informative view functions
    /// @notice calculates total mintPrice based on mintCaller, mintQuantity, targetPress, and tokenId
    function totalMintPrice(address targetPress, uint256 tokenId, uint64 mintQuantity, address mintCaller) external view returns (uint256);    
    /// @notice checks if a given tokenId for a given Press has been initialized
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool);    
    /// @notice Function to return global primsarySaleFee details for the given tokenId for a given Press
    function maxSupply() external view returns (uint64);
}
