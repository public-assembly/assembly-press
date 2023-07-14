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

import {IAP721} from "../interfaces/IAP721.sol";

import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

import {AP721PressDatabaseSkeletonStorageV1} from "./storage/AP721DatabaseSkeletonStorageV1.sol";
import {IAP721Database} from "../interfaces/IAP721Database.sol";

import "sstore2/SSTORE2.sol";

/**
 * @title AP721DatabaseV1
 * @notice V1 generic database architecture
 * @dev Strategy specific databases can inherit this to ensure compatibility with Assembly Press framework.
 *      All write functions are virtual to allow for modifications
 * @dev By default, there are no fees or validity checks applied to data storage
 * @author Max Bochman
 * @author Salief Lewis
 */
contract AP721DatabaseV1 is
    AP721DatabaseSkeletonStorageV1,
    IAP721Database
{
    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Checks if target AP721 has been initialized in the database
     */
    modifier requireInitialized(address target) {
        if (ap721Settings[target].initialized != 1) {
            revert Target_Not_Initialized();
        }

        _;
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // AP721 SETUP
    //////////////////////////////

    function setupAP721(
        address initialOwner, 
        bytes memory databaseInit,
        address factory,
        bytes memory factoryInit
    ) nonReentrant requireAllowedFactory external virtual returns (address) {
        // Call factory to create + initialize a new AP721Proxy
        address newAP721 = IAP721Factory(factory).create(
            initialOwner,
            factoryInit
        );
        // Initialize new AP721Proxy in database
        ap721Settings[newAP721].initialized = 1;
        // Decode database init
        (
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit,
        ) = abi.decode(databaseInit, (address, bytes, address, bytes, address));
        // Set logic + renderer contracts for AP721Proxy
        _setLogic(newAP721, logic, logicInit);
        _setRenderer(newAP721, renderer, rendererInit);
        // Return address of newly created AP721Proxy
        return newAP721;
    }        

    //////////////////////////////
    // PRESS SETTINGS
    //////////////////////////////

    // setLogic(address)
    // setRenderer
    // multiSetLogic
    // multiSetRenderer
    // _setLogic()
    // _setRenderer()

    //////////////////////////////
    // DATA STORAGE
    //////////////////////////////    

    /// @dev Skeleton does not implement a data validation check. Any data types can be stored
    ///     Be sure to implement an internal _validateData check in your own implementation if needed
    function store(address target, uint256 quantity, bytes memory data) external virtual {
        // Cache msg.sender + msg.value
       (address sender, uint256 msgValue) = (_msgSender(), msg.value);
        // Check if target has been initialized
        if (ap721Settings[target].initialized != 1) {
            revert Target_Not_Initialized();
        }
        // Check if sender can store data in target
        if (IAP721Logic(ap721Settings[target].logic).canStore(target, sender, quantity) == false) {
            revert No_Store_Access();
        }    

        // Decode token data
        bytes[] memory tokens = abi.decode(data, (bytes[]));

        // Store data for each token
        for (uint256 i = 0; i < quantity; ++i) {
            // Cache storedCounter
            // NOTE: storedCounter trails associated tokenId by 1
            uint256 storedCounter = ap721Settings[target].storedCounter;
            // Use sstore2 to store bytes segments from bytes array                
            tokenData[target][storedCounter] = SSTORE2.write(
                tokens[i]
            );       
            emit DataStored(
                target, 
                sender,
                storedCounter, // this trails tokenId associated with storage by 1  
                idToData[sender][storedCounter]
            );                                       
            // Increment target storedCounter after storing data
            ++ap721Settings[target].storedCounter;              
        }       

        // Mint tokens to sender
        IAP721(target).mint(quantity, sender);        
    }  

    //////////////////////////////
    // MULTI TARGET DATA STORAGE
    //////////////////////////////     

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // STATUS CHECKS
    //////////////////////////////

    /**
     * @notice Checks value of initialized variable in ap721Settings mapping for target
     * @param target AP721 contract to check initialization status
     * @return initialized True/false bool if press is initialized
     */
    function isInitialized(
        address target
    ) external view returns (bool initialized) {
        // Return false if targetPress has not been initialized
        if (ap721Settings[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }     

    //////////////////////////////
    // ACCESS CHECKS
    //////////////////////////////

    //////////////////////////////
    // DATA RENDERING
    //////////////////////////////

}
