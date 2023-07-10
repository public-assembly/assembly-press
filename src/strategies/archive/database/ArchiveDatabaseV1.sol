// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

import {ERC1155PressDatabaseSkeletonV1} from "../../../core/token/ERC1155/database/ERC1155PressDatabaseSkeletonV1.sol";
import {ERC1155Press} from "../../../core/token/ERC1155/ERC1155Press.sol";
import {DualOwnable} from "../../../core/utils/ownable/dual/DualOwnable.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";

/**
* @title ArchiveDatabaseV1
* @notice Archive focused database built for Assembly Press framework
* @dev Inherits from ERC1155PressDatabaseSkeletonV1 and implements IERC1155PressDatabase required
*       `setOfficiaFactory`, `storeData`, and `overwriteData` functions 
* @author Max Bochman
* @author Salief Lewis
*/
contract ArchiveDatabaseV1 is ERC1155PressDatabaseSkeletonV1, DualOwnable { 

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////        

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////       

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////   

    /// @notice prevents user from providing invalid inputs
    error Invalid_Input_Length();

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR 
    ////////////////////////////////////////////////////////////     

    /**
    * @dev Sets primary + secondary contract ownership
    * @param _initialOwner The initial owner address
    * @param _initialSecondaryOwner The initial secondary owner address
    */
    constructor (address _initialOwner, address _initialSecondaryOwner) DualOwnable(_initialOwner, _initialSecondaryOwner) {}    

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    ////////////////////////////////////////////////////////////   

    //////////////////////////////
    // ADMIN 
    //////////////////////////////

    /**
    * @notice Gives factory ability to initalize contracts in this database
    * @dev Ability cannot be removed once set
    * @param factory Address of factory to grant initialise ability
    */
    function setOfficialFactory(address factory) eitherOwner external {
        _officialFactories[factory] = true;
        emit NewFactoryAdded(msg.sender, factory);
    }

    //////////////////////////////
    // DATA VALIDATION
    ////////////////////////////// 

    /**
    * @dev Internal helper function that checks validity of data to be stored
    *     The function will revert if the data cannot be decoded properly, causing the transaction to fail
    * @param data Data to validate
    */
    function _validateData(bytes memory data) internal pure {
        abi.decode(data, (string));
    }     


    //////////////////////////////
    // TOKEN INITIALIZATION
    //////////////////////////////    

    /**
     * @notice Default database initializer for a given token
     * @dev Initializes settings and data for a given token
     * @param databaseInit data to init with
     * @param data data to store for token
     */
    function initializeTokenWithData(
        address initializeCaller,
        bytes memory databaseInit,
        bytes memory data
    ) external returns (uint256) {

        // Cache msg.sender -- which is Press if called correctly
        address sender = msg.sender;          
        
        if (pressSettingsInfo[sender].initialized != 1) {
            revert Press_Not_Initialized();
        }      

        // Retrieve + cache counter for token to store data for
        uint256 storeCounter = pressSettingsInfo[sender].storedCounter;        

        // Initialize storage slot for token for Press
        tokenSettingsInfo[sender][storeCounter].initialized = 1;

        // Data format: tokenLogic, tokenLogicInit, tokenRenderer, tokenRendererInit
        (
            address tokenLogic,
            bytes memory tokenLogicInit,
            address tokenRenderer,
            bytes memory tokenRendererInit
        ) = abi.decode(databaseInit, (address, bytes, address, bytes));

        if (tokenLogic != address(0)) {
          _setTokenLogic(sender, storeCounter, tokenLogic, tokenLogicInit);
        }
        if (tokenRenderer != address(0)) {
          _setTokenRenderer(sender, storeCounter, tokenRenderer, tokenRendererInit);
        }

        // Check data being stored is valid
        _validateData(data);        

        // Store data for token
        idToData[sender][storeCounter] = SSTORE2.write(data);

        emit DataStored(
            sender, 
            initializeCaller,
            storeCounter + 1,  
            idToData[sender][storeCounter]
        );             

        // Increment storeCounter and return new value
        return ++storeCounter;
    }    

    //////////////////////////////
    // OVERWRITE DATA
    //////////////////////////////                

    /**
    * @dev Updates sstore2 data pointers for already existing tokens
    * @param overwriteCaller address of account initiating `update()` from targetPress
    * @param tokenIds arbitrary encoded bytes data
    * @param newData data passed in alongside update call
    */
    function overwriteData(address overwriteCaller, uint256[] memory tokenIds, bytes[] calldata newData) external {
        // Cache msg.sender -- which is the Press if called correctly
        address targetPress = msg.sender;

        // Prevents users from submitting invalid inputs
        if (tokenIds.length != newData.length) {
            revert Invalid_Input_Length();
        }        

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            if (tokenSettingsInfo[targetPress][tokenIds[1]-1].initialized != 1) {
                revert Token_Not_Initialized();
            }                   
            // Check data is valid
            _validateData(newData[i]);            
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1] = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  

        // TODO: create a memory array of newPointer addresses so that
        //  DataOverwritten event can move outside of for loop and just trigger once
        //      with tokenIds and newPointers arrays as values
        //      and then upate for 721 as well
    }                 
}