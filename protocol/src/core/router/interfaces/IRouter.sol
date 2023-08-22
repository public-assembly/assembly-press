// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

interface IRouter {

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////        

    event FactoryRegistered(
        address sender,
        address[] factories,
        bool[] statuses
    );
    event PressRegistered(
        address sender,
        address factory,
        address newPress
    );
    event TokenDataStored(
        address sender,
        address press,
        uint256[] tokenIds,
        address[] pointers
    );
    event TokenDataOverwritten(
        address sender,
        address press,
        uint256[] tokenIds,
        address[] pointers
    );    
    event TokenDataRemoved(
        address sender,
        address press,
        uint256[] tokenIds
    );       
    event PressDataUpdated(
        address sender,
        address press,
        address pointer
    );

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Error when trying to use a factory that is not registered
    error Invalid_Factory();
    /// @notice Error when trying to target a press that is not registered
    error Invalid_Press();    
    /// @notice Error when inputting arrays with non matching length
    error Input_Length_Mismatch();
}
