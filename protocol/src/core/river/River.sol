// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IChannel} from "../channel/interfaces/IChannel.sol";
import {IBranch} from "../branch/interfaces/IBranch.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title River
 */
contract River is ReentrancyGuard {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    mapping(address => bool) public branchRegistry;
    mapping(address => bool) public channelRegistry;

    //////////////////////////////////////////////////
    // EVENT
    //////////////////////////////////////////////////        

    event BranchRegistered(
        address sender,
        address[] branches,
        bool[] statuses
    );

    event ChannelRegistered(
        address sender,
        address branch,
        address newChannel
    );

    event TokenDataStored(
        address sender,
        address channel,
        uint256[] tokenIds,
        address[] pointers
    );
    event TokenDataOverwritten(
        address sender,
        address channel,
        uint256[] tokenIds,
        address[] pointers
    );    
    event TokenDataRemoved(
        address sender,
        address channel,
        uint256[] tokenIds
    );       

    event ChannelDataStored(
        address sender,
        address channel,
        address pointers
    );
    event ChannelDataOverwritten(
        address sender,
        address channel,
        address pointers
    );    
    event ChannelDataRemoved(
        address sender,
        address channel
    );           

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Error when trying to use a branch that is not registered
    error Invalid_Branch();
    /// @notice Error when trying to target a channel that is not registered
    error Invalid_Channel();    
    /// @notice Error when inputting arrays with non matching length
    error Input_Length_Mistmatch();

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    //////////////////////////////
    // ADMIN
    //////////////////////////////    

    function registerBranches(address[] memory branches, bool[] memory statuses) external {
        if (branches.length != statuses.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < branches.length; ++i) {
            branchRegistry[branches[i]] = statuses[i]
        }        
        emit BranchRegistered(msg.sender, branches, statuses);
    }

    //////////////////////////////
    // CHANNEL CREATION
    //////////////////////////////      

    function branch(address branchImpl, bytes memory branchInit) nonReentrant external payable returns (address) {
        if (!branchRegistry[branchImpl]) revert Invalid_Branch();
        address channel = IBranch(branchImpl).createChannel(branchInit);
        channelRegistry[channel] = true;
        emit ChannelRegistered(msg.sender, branchImpl, channel);
        return channel;
    }

    function branchBatch(address[] memory branchImpls, bytes[] memory branchInits) nonReentrant external payable returns (address[]) {
        if (branchImpls.length != branchInits.length) revert Input_Length_Mistmatch();   
        address[] memory channels = new address[](branchImpls.length);
        for (uint256 i; i < branchImpls.length; ++i) {
            if (!branchRegistry[branchImps[il]) revert Invalid_Branch();
            address channel = IBranch(branchImpls[i]).createChannel(branchInits[i]);
            channelRegistry[channel] = true;
            emit ChannelRegistered(msg.sender, branchImpls[i], channel);
            channels[i] = channel;
        }     
        return channels;
    }    

    //////////////////////////////
    // SINGLE CHANNEL INTERACTIONS
    //////////////////////////////      

    /* ~~~ Token Level Interactions ~~~ */

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

    /* ~~~ Channel Level Interactions ~~~ */

    function storeChannelData(address channel, bytes memory data) nonReentrant external payable {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (address pointer) = IChannel(channel).storeChannelData(msg.sender, data);
        emit ChannelDataStored(msg.sender, channel, pointer);
    }

    function overwriteChannelData(address channel, bytes memory data) nonReentrant external {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (address pointer) = IChannel(channel).overwriteChannelData(msg.sender, data);
        emit ChannelDataOverwritten(msg.sender, channel, pointer);
    }    

    function removeChannelData(address channel, bytes memory data) nonReentrant external {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        IChannel(channel).removeChannelData(msg.sender, data);
        emit ChannelDataRemoved(msg.sender, channel);
    }        

    //////////////////////////////
    // MULTI CHANNEL INTERACTIONS
    //////////////////////////////    

    /* ~~~ Token Level Interactions ~~~ */    

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

    /* ~~~ Channel Level Interactions ~~~ */

    function storeChannelDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external payable {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (address pointer) = IChannel(channels[i]).storeChannelData(msg.sender, datas[i]);
            emit ChannelDataStored(msg.sender, channels[i], pointer);
        }    
    }

    function overwriteChannelDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            (address pointer) = IChannel(channels[i]).overwriteChannelData(msg.sender, datas[i]);
            emit ChannelDataOverwritten(msg.sender, channels[i], pointer);
        }    
    }    

    function removeChannelDataMulti(address[] memory channels, bytes[] memory datas) nonReentrant external {
        if (channels.length != datas.length) revert Input_Length_Mistmatch();
        for (uint256 i; i < channels.length; ++i) {
            if (!channelRegistry[channels[i]]) revert Invalid_Channel();
            IChannel(channels[i]).removeChannelData(msg.sender, datas[i]);
            emit ChannelDataRemoved(msg.sender, channels[i]);
        }    
    }         
}
