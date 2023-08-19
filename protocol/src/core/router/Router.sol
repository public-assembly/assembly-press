// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IRouter} from "./interfaces/IRouter.sol";
import {IPress} from "../press/interfaces/IPress.sol";
import {IFactory} from "../factory/interfaces/IFactory.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/*
    NOTE:
    - This could be a hyperstructure if we remove the factory registry
    - Applications can filter for events from presses created from their specific factory implemnetations
    - Factory implementations can be fully perimissioned without blocking anyone from
    writing their own factories to create the presses they want
    - Can also write + deploy unpermissioned factory implementations from the beginning 
*/

/**
 * @title Router
 */
contract Router is IRouter, Ownable, ReentrancyGuard {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    mapping(address => bool) public factoryRegistry;
    mapping(address => bool) public pressRegistry;

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    //////////////////////////////
    // ADMIN
    //////////////////////////////    

    function registerFactories(address[] memory factories, bool[] memory statuses) onlyOwner external {
        if (factories.length != statuses.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < factories.length; ++i) {
            factoryRegistry[factories[i]] = statuses[i];
        }        
        emit FactoryRegistered(msg.sender, factories, statuses);
    }

    //////////////////////////////
    // Press CREATION
    //////////////////////////////      

    function setup(address factoryImpl, bytes memory factoryInit) nonReentrant external payable returns (address) {
        if (!factoryRegistry[factoryImpl]) revert Invalid_Factory();
        address press = IFactory(factoryImpl).createPress(msg.sender, factoryInit);
        pressRegistry[press] = true;
        emit PressRegistered(msg.sender, factoryImpl, press);
        return press;
    }

    function setupBatch(address[] memory factoryImpls, bytes[] memory factoryInits) nonReentrant external payable returns (address[] memory) {
        if (factoryImpls.length != factoryInits.length) revert Input_Length_Mistmatch();   
        address[] memory presses = new address[](factoryImpls.length);
        for (uint256 i; i < factoryImpls.length; ++i) {
            if (!factoryRegistry[factoryImpls[i]]) revert Invalid_Factory();
            address press = IFactory(factoryImpls[i]).createPress(msg.sender, factoryInits[i]);
            pressRegistry[press] = true;
            emit PressRegistered(msg.sender, factoryImpls[i], press);
            presses[i] = press;
        }     
        return presses;
    }    

    //////////////////////////////
    // SINGLE PRESSS INTERACTIONS
    //////////////////////////////      

    /* ~~~ Press Data Interactions ~~~ */

    function updatePressData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (address pointer) = IPress(press).updatePressData{value: msg.value}(msg.sender, data);
        emit PressDataUpdated(msg.sender, press, pointer);
    }         

    /* ~~~ Token Data Interactions ~~~ */

    function storeTokenData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (uint256[] memory tokenIds, address[] memory pointers) = IPress(press).storeTokenData{value: msg.value}(msg.sender, data);
        emit TokenDataStored(msg.sender, press, tokenIds, pointers);
    }

    function overwriteTokenData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (uint256[] memory tokenIds, address[] memory pointers) = IPress(press).overwriteTokenData{value: msg.value}(msg.sender, data);
        emit TokenDataOverwritten(msg.sender, press, tokenIds, pointers);
    }    

    function removeTokenData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (uint256[] memory tokenIds) = IPress(press).removeTokenData{value: msg.value}(msg.sender, data);
        emit TokenDataRemoved(msg.sender, press, tokenIds);
    }    

    //////////////////////////////
    // MULTI PRESS INTERACTIONS
    //////////////////////////////    

    // NOTE: These functions dont work now since arent passing value to the forwarding contracts

    /* ~~~ Press Data Interactions ~~~ */

    function updatePressDataMulti(address[] memory presses, bytes[] memory datas, uint256[] memory values) nonReentrant external payable {
        if (presses.length != datas.length && presses.length != values.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < presses.length; ++i) {
            if (!pressRegistry[presses[i]]) revert Invalid_Press();
            (address pointer) = IPress(presses[i]).updatePressData{value: values[i]}(msg.sender, datas[i]);
            emit PressDataUpdated(msg.sender, presses[i], pointer);
        }    
    }      

    /* ~~~ Token Data Interactions ~~~ */    

    function storeTokenDataMulti(address[] memory presses, bytes[] memory datas, uint256[] memory values) nonReentrant external payable {
        if (presses.length != datas.length && presses.length != values.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < presses.length; ++i) {
            if (!pressRegistry[presses[i]]) revert Invalid_Press();
            (uint256[] memory tokenIds, address[] memory pointers) = IPress(presses[i]).storeTokenData{value: values[i]}(msg.sender, datas[i]);
            emit TokenDataStored(msg.sender, presses[i], tokenIds, pointers);
        }    
    }

    function overwriteTokenDataMulti(address[] memory presses, bytes[] memory datas, uint256[] memory values) nonReentrant external payable {
        if (presses.length != datas.length && presses.length != values.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < presses.length; ++i) {
            if (!pressRegistry[presses[i]]) revert Invalid_Press();
            (uint256[] memory tokenIds, address[] memory pointers) = IPress(presses[i]).overwriteTokenData{value: values[i]}(msg.sender, datas[i]);
            emit TokenDataOverwritten(msg.sender, presses[i], tokenIds, pointers);
        }    
    }    

    function removeTokenDataMulti(address[] memory presses, bytes[] memory datas, uint256[] memory values) nonReentrant external payable {
        if (presses.length != datas.length && presses.length != values.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < presses.length; ++i) {
            if (!pressRegistry[presses[i]]) revert Invalid_Press();
            (uint256[] memory tokenIds) = IPress(presses[i]).removeTokenData{value: values[i]}(msg.sender, datas[i]);
            emit TokenDataRemoved(msg.sender, presses[i], tokenIds);
        }    
    }        
}
