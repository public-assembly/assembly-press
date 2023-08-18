// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface IRiver {

    //////////////////////////////////////////////////
    // EVENTS
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

}
