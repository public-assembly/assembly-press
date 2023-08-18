// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IBranch} from "./interfaces/IBranch.sol";
import {Channel} from "../channel/Channel.sol";
import {ChannelProxy} from "../channel/proxy/ChannelProxy.sol";

/**
 * @title Branch
 */
contract Branch is IBranch {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    address public river;
    address public channel;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////    

    constructor(address riverImpl, address channelImpl) {
        river = riverImpl;
        channel = channelImpl;
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    // dont think this needs a reentrancy guard, since a callback to the Branch mid createChannel
    //      execution cant do anyting malicious? only function is to create another new channel?
    function createChannel(bytes memory init) external returns (address) {        
        if (msg.sender != river) revert Sender_Not_River();
        // Decode init data
        (Inputs memory inputs) = abi.decode(init, (Inputs));
        // Configure ownership details in proxy constructor
        ChannelProxy newChannel = new ChannelProxy(channel, "");
        // Initialize AP721Proxy
        Channel(payable(address(newChannel))).initialize({
            channelName: inputs.channelName,
            initialOwner: inputs.initialOwner,
            riverImpl: river, // input comes from local storage not decode
            feeRouterImpl: inputs.feeRouterImpl,
            logic: inputs.logic,
            logicInit: inputs.logicInit,
            renderer: inputs.renderer,
            rendererInit: inputs.rendererInit,
            advancedSettings: inputs.advancedSettings
        });
        return address(newChannel);
    }
}