// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IContractLogic {  
    
    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||


    // initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    /// @notice checks if a certain address can access mint functionality for a given Press + recepients + quantity combination
    function canMintNew(
        address targetPress, 
        uint256[] memory mintQuantity, 
        address[] memory mintRecipients, 
        address mintCaller
    ) external view returns (bool);



}