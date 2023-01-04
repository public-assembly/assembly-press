// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ILogic {  

    // initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    // access control functions
    /// @notice checks if a certain address can update the Config struct on a given Press 
    function canUpdatePressConfig(address targetPress, address updateCaller) external view returns (bool);
    /// @notice checks if a certain address can access mint functionalitty for a given Press + quantity combination
    function canMint(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (bool);
    /// @notice checks if a certain address can edit metadata post metadata initialization for a given Press
    function canEditMetadata(address targetPress, address editCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the withdraw function for a given Press
    function canWithdraw(address targetPress, address withdrawCaller) external view returns (bool);    
    /// @notice checks if a certain address can call the burn function for a given Press
    function canBurn(address targetPress, address burnCaller) external view returns (bool);    
    /// @notice checks if a certain address can upgrade the underlying implementation for a given Press
    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);
    /// @notice checks if a certain address can transfer ownership of a given Press
    function canTransfer(address targetPress, address transferCaller) external view returns (bool);    
    
    // informative view functions
    /// @notice calculates total mintPrice based on mintCaller, mintQuantity, and targetPress
    function totalMintPrice(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (uint256);    
    /// @notice checks if a given Press has been initialized
    function isInitialized(address targetPress) external view returns (bool);    
    /// @notice Function to return global primsarySaleFee details for the given Press
    function maxSupply() external view returns (uint64);
}
