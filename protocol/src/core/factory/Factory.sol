// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IFactory} from "./interfaces/IFactory.sol";
import {Press} from "../press/Press.sol";
import {PressProxy} from "../press/proxy/PressProxy.sol";

/**
 * @title Factory
 */
contract Factory is IFactory {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    address public router;
    address public pressImpl;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////    

    constructor(address _router, address _pressImpl) {
        router = _router;
        pressImpl = _pressImpl;
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    // dont think this needs a reentrancy guard, since a callback to the Factory mid createPress
    //      execution cant do anyting malicious? only function is to create another new press?
    function createPress(address sender, bytes memory init) external returns (address) {        
        if (msg.sender != router) revert Sender_Not_Router();
        /* 
            Could put factory logic check here for sender access
            Could also take out sender from being an input, but seems nice to have
        */        
        // Decode init data
        (Inputs memory inputs) = abi.decode(init, (Inputs));
        // Configure ownership details in proxy constructor
        PressProxy newPress = new PressProxy(pressImpl, "");
        // Initialize AP721Proxy
        Press(payable(address(newPress))).initialize({
            pressName: inputs.pressName,
            initialOwner: inputs.initialOwner,
            router: router, // input comes from local storage not decode
            logic: inputs.logic,
            logicInit: inputs.logicInit,
            renderer: inputs.renderer,
            rendererInit: inputs.rendererInit,
            advancedSettings: inputs.advancedSettings
        });
        return address(newPress);
    }
}
