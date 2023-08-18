// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IRiver} from "./interfaces/IRiver.sol";
import {IChannel} from "../channel/interfaces/IChannel.sol";
import {IBranch} from "../branch/interfaces/IBranch.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

/*
    NOTE:
    - This could be a hyperstructure if we remove the branch registry
    - Applications can filter for events from channels created from their specific branch implemnetations
    - Branch implementations can be fully perimissioned without blocking anyone from
    writing their own branches to create the channels they wants
*/

/**
 * @title River
 */
contract River is IRiver, Ownable, ReentrancyGuard {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    mapping(address => bool) public branchRegistry;
    mapping(address => bool) public channelRegistry;

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    //////////////////////////////
    // ADMIN
    //////////////////////////////    

    function registerBranches(address[] memory branches, bool[] memory statuses) onlyOwner external {
        if (branches.length != statuses.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < branches.length; ++i) {
            branchRegistry[branches[i]] = statuses[i];
        }        
        emit BranchRegistered(msg.sender, branches, statuses);
    }

    //////////////////////////////
    // CHANNEL CREATION
    //////////////////////////////      

    function branch(address branchImpl, bytes memory branchInit) nonReentrant external payable returns (address) {
        if (!branchRegistry[branchImpl]) revert Invalid_Branch();
        address channel = IBranch(branchImpl).createChannel(msg.sender, branchInit);
        channelRegistry[channel] = true;
        emit ChannelRegistered(msg.sender, branchImpl, channel);
        return channel;
    }

    function branchBatch(address[] memory branchImpls, bytes[] memory branchInits) nonReentrant external payable returns (address[] memory) {
        if (branchImpls.length != branchInits.length) revert Input_Length_Mistmatch();   
        address[] memory channels = new address[](branchImpls.length);
        for (uint256 i; i < branchImpls.length; ++i) {
            if (!branchRegistry[branchImpls[i]]) revert Invalid_Branch();
            address channel = IBranch(branchImpls[i]).createChannel(msg.sender, branchInits[i]);
            channelRegistry[channel] = true;
            emit ChannelRegistered(msg.sender, branchImpls[i], channel);
            channels[i] = channel;
        }     
        return channels;
    }    

    //////////////////////////////
    // SINGLE CHANNEL INTERACTIONS
    //////////////////////////////      

    /* ~~~ Channel Data Interactions ~~~ */

    function updateChannelData(address channel, bytes memory data) nonReentrant external payable {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (address pointer) = IChannel(channel).updateChannelData(msg.sender, data);
        emit ChannelDataUpdated(msg.sender, channel, pointer);
    }         

    /* ~~~ Token Data Interactions ~~~ */

    function storeTokenData(address channel, bytes memory data) nonReentrant external payable {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (uint256[] memory tokenIds, address[] memory pointers) = IChannel(channel).storeTokenData(msg.sender, data);
        emit TokenDataStored(msg.sender, channel, tokenIds, pointers);
    }

    function overwriteTokenData(address channel, bytes memory data) nonReentrant external {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (uint256[] memory tokenIds, address[] memory pointers) = IChannel(channel).overwriteTokenData(msg.sender, data);
        emit TokenDataOverwritten(msg.sender, channel, tokenIds, pointers);
    }    

    function removeTokenData(address channel, bytes memory data) nonReentrant external {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (uint256[] memory tokenIds) = IChannel(channel).removeTokenData(msg.sender, data);
        emit TokenDataRemoved(msg.sender, channel, tokenIds);
    }    

    //////////////////////////////
    // MULTI CHANNEL INTERACTIONS
    //////////////////////////////    

    /* ~~~ Channel Data Interactions ~~~ */

    function updateChannelDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external payable {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (address pointer) = IChannel(channels[i]).updateChannelData(msg.sender, datas[i]);
            emit ChannelDataUpdated(msg.sender, channels[i], pointer);
        }    
    }      

    /* ~~~ Token Data Interactions ~~~ */    

    function storeTokenDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external payable {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (uint256[] memory tokenIds, address[] memory pointers) = IChannel(channels[i]).storeTokenData(msg.sender, datas[i]);
            emit TokenDataStored(msg.sender, channels[i], tokenIds, pointers);
        }    
    }

    function overwriteTokenDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (uint256[] memory tokenIds, address[] memory pointers) = IChannel(channels[i]).overwriteTokenData(msg.sender, datas[i]);
            emit TokenDataOverwritten(msg.sender, channels[i], tokenIds, pointers);
        }    
    }    

    function removeTokenDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (uint256[] memory tokenIds) = IChannel(channels[i]).removeTokenData(msg.sender, datas[i]);
            emit TokenDataRemoved(msg.sender, channels[i], tokenIds);
        }    
    }        
}
