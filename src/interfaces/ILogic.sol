// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ILogic {
    
    // function name() external view returns (string memory); UNNCESSSARY?
    
    function maxSupply() external view returns (uint64);

    function maxSupplyCheck(address targetPress, uint64 mintQuantity) external view returns (bool);

    function isInitialized(address targetPress) external view returns (bool);

    function canMint(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (bool);

    function totalMintPrice(address targetPress, uint64 mintQuantity, address mintCaller) external view returns (uint256);

    function canWithdraw(address targetPress, address withdrawCaller) external view returns (bool);    

    function canEditMetadata(address targetPress, address editCaller) external view returns (bool);    

    function canUpdatePressConfig(address targetPress, address updateCaller) external view returns (bool);

    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);
    
    function canBurn(address targetPress, address burnCaller) external view returns (bool);

    function initializeWithData(bytes memory initData) external;
    
}