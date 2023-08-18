// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IPressTypesV1} from "../../press/types/IPressTypesV1.sol";

interface IFactory {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
    struct Inputs {
        string pressName; 
        address initialOwner;
        address feeRouterImpl;
        address logic;
        bytes logicInit;
        address renderer;
        bytes rendererInit;
        IPressTypesV1.AdvancedSettings advancedSettings;
    }

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Error when msg.sender is not the stored database impl
    error Sender_Not_Router();    

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////       

    /// @notice Deploys and initializes new press
    function createPress(address sender, bytes memory init) external returns (address);
}
