// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {Channel} from "../channel/Channel.sol";
import {ChannelProxy} from "../channel/proxy/ChannelProxy.sol";
import {IChannel} from "../channel/interfaces/IChannel.sol";
import {IChannelTypesV1} from "../channel/types/IChannelTypesV1.sol";
import {IBranch} from "../branch/interfaces/IBranch.sol";
import {Version} from "../../utils/Version.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title River
 */
contract River is Version(1), ReentrancyGuard {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////
    
    mapping(address => bool) public branchRegistry;
    mapping(address => bool) public channelRegistry;

    //////////////////////////////////////////////////
    // EVENT
    //////////////////////////////////////////////////        

    event RegisteredBranches(
        address sender,
        address[] branches
    );

    event NewChannel(
        address sender,
        address branch,
        address newChannel
    );

    event DataStored(
        address sender,
        address channel,
        uint256[] tokenIds,
        address[] pointers
    );

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Error when trying to use a branch that is not registered
    error Invalid_Branch();
    /// @notice Error when trying to target a channel that is not registered
    error Invalid_Channel();    

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////  

    function registerBranches(address[] memory branches) external {
        address[] memory newBranches = new address[](branches.length);
        for (uint256 i; i < branches.length; ++i) {
            branchRegistry[branches[i]] = true;
            newBranches[i] = branches[i];
        }        
        emit RegisteredBranches(msg.sender, newBranches);
    }

    function branch(address branchImpl, bytes memory branchInit) external returns (address) {
        if (!branchRegistry[branchImpl]) revert Invalid_Branch();
        address channel = IBranch(branchImpl).createChannel(branchInit);
        channelRegistry[channel] = true;
        emit NewChannel(msg.sender, branchImpl, channel);
        return channel;
    }

    function store(address channel, bytes memory data) external payable {
        if (!channelRegistry[channel]) revert Invalid_Channel();
        (uint256[] memory tokenIds, address[] memory pointers) = IChannel(channel).store(msg.sender, data);
        emit DataStored(msg.sender, channel, tokenIds, pointers);
    }
}
