// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IChannelTypesV1} from "../../channel/types/IChannelTypesV1.sol";

interface IBranch {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    
    
    struct Inputs {
        string channelName; 
        address initialOwner;
        address feeRouterImpl;
        address logic;
        bytes logicInit;
        address renderer;
        bytes rendererInit;
        IChannelTypesV1.AdvancedSettings advancedSettings;
    }

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Error when msg.sender is not the stored database impl
    error Sender_Not_River();    

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////       

    /// @notice Deploys and initializes new channel
    function createChannel(bytes memory init) external returns (address);
}
