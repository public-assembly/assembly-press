// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.
*/

/**
 * @title IDualOwnable
 * @author Max Bochman
 * @notice The external Ownable events, errors, and functions
 */
interface IDualOwnable {
    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    /// @notice Emitted when ownership has been updated
    /// @param prevOwner The previous owner address
    /// @param newOwner The new owner address
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @notice Emitted when an ownership transfer is pending
    /// @param owner The current owner address
    /// @param pendingOwner The pending new owner address
    event OwnerPending(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when a pending ownership transfer has been canceled
    /// @param owner The current owner address
    /// @param canceledOwner The canceled owner address
    event OwnerCanceled(address indexed owner, address indexed canceledOwner);

    /// @notice Emitted when secondary ownership has been updated
    /// @param prevSecondaryOwner The previous secondary owner address
    /// @param newSecondaryOwner The new secondary owner address
    event SecondaryOwnerUpdated(address indexed prevSecondaryOwner, address indexed newSecondaryOwner);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    /// @dev Reverts if an unauthorized user calls an owner function
    error ONLY_OWNER();
    /// @dev Reverts if an unauthorized user calls a pending owner function
    error ONLY_PENDING_OWNER();
    /// @dev Reverts if an unauthorized user calls an eitherOwner function
    error NOT_EITHER_OWNER();
    /// @dev Owner cannot be the zero/burn address
    error OWNER_CANNOT_BE_ZERO_ADDRESS();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Forces an ownership transfer
    /// @param newOwner The new owner address
    function transferOwnership(address newOwner) external;
    /// @notice Initiates a two-step ownership transfer
    /// @param newOwner The new owner address
    function safeTransferOwnership(address newOwner) external;
    /// @notice Accepts an ownership transfer
    function acceptOwnership() external;
    /// @notice Cancels a pending ownership transfer
    function cancelOwnershipTransfer() external;
    /// @notice Forces a secondary ownership transfer
    /// @param newSecondaryOwner The new secondary owner address
    function transferSecondaryOwnership(address newSecondaryOwner) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    /// @notice The address of the owner
    function owner() external view returns (address);
    /// @notice The address of the pending owner
    function pendingOwner() external view returns (address);
    /// @notice The address of the secondary owner
    function secondaryOwner() external view returns (address);
}
