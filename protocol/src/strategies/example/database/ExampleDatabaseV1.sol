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

import {AP721DatabaseV1} from "../../../core/token/AP721/database/AP721DatabaseV1.sol";
import {IAP721DatabaseAccess} from "../../../core/token/AP721/database/interfaces/extensions/IAP721DatabaseAccess.sol";
import {IAP721DatabaseMultiTarget} from "../../../core/token/AP721/database/interfaces/extensions/IAP721DatabaseMultiTarget.sol";

import {AP721} from "../../../core/token/AP721/nft/AP721.sol";
import {IAP721} from "../../../core/token/AP721/nft/interfaces/IAP721.sol";
import {IAP721Database} from "../../../core/token/AP721/database/interfaces/IAP721Database.sol";
import {IAP721Factory} from "../../../core/token/AP721/factory/interfaces/IAP721Factory.sol";
import {IAP721LogicAccess} from "../../../core/token/AP721/logic/interfaces/extensions/IAP721LogicAccess.sol";

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "sstore2/SSTORE2.sol";

/**
 * @title ExampleDatabaseV1
 * @notice Example database that shows recommended ways for augmenting inherited AP721DatabaseV1 functionality
 * @dev This default implementation does not facilitate fees or validity checks for data storage
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ExampleDatabaseV1 is AP721DatabaseV1, IAP721DatabaseAccess, IAP721DatabaseMultiTarget {

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // AP721 SETUP
    //////////////////////////////

    /* Inherits default `setupAP721` + `setSettings` impl from abstract AP721Database */

    //////////////////////////////
    // AP721 SETTINGS
    //////////////////////////////

    /**
     * @notice Facilitates updating of logic contract for a given AP721
     * @dev logicInit can be blank
     * @param target AP721 to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function setLogic(address target, address logic, bytes memory logicInit) external override(AP721DatabaseV1) requireInitialized(target) {
        // Request settings access from logic contract
        if (!IAP721LogicAccess(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(target, logic, logicInit);
        emit LogicUpdated(target, logic);
    }

    /**
     * @notice Facilitates updating of renderer contract for a given AP721
     * @dev rendererInit can be blank
     * @param target AP721 to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function setRenderer(address target, address renderer, bytes memory rendererInit) external override(AP721DatabaseV1) requireInitialized(target) {
        // Request settings access from renderer contract
        if (!IAP721LogicAccess(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) revert No_Settings_Access();
        // Update + initialize new renderer contract
        _setRenderer(target, renderer, rendererInit);
        emit RendererUpdated(target, renderer);
    }

    //////////////////////////////
    // DATA STORAGE
    //////////////////////////////

    /**
     * @notice Facilitates token level data storage
     * @dev Stores data for a specified target address and mints storage receipts from that target to the msg.sender
     * @dev Inherits no-op `validateData` function from AP721Database. Any data can be stored
     * @param target Target address to store data for
     * @param data Data to be stored
     */
    function store(address target, bytes memory data) external override(AP721DatabaseV1, IAP721Database) requireInitialized(target) {
        // Cache msg.sender
        address sender = msg.sender;
        // Decode token data
        bytes[] memory tokens = abi.decode(data, (bytes[]));        
        // Cache quantity
        uint256 quantity = tokens.length;        

        // Check if sender can store data in target
        if (!IAP721LogicAccess(ap721Settings[target].logic).getStoreAccess(target, sender, quantity)) revert No_Store_Access();

        // Store data for each token
        for (uint256 i = 0; i < quantity; ++i) {
            // Check data is valid
            _validateData(tokens[i]);
            // Cache storageCounter
            // NOTE: storageCounter trails associated tokenId by 1
            uint256 storageCounter = ap721Settings[target].storageCounter;
            // Use sstore2 to store bytes segments
            address pointer = tokenData[target][storageCounter] = SSTORE2.write(tokens[i]);
            emit DataStored(
                target,
                sender,
                storageCounter,
                pointer
            );
            // Increment target storageCounter after storing data
            ++ap721Settings[target].storageCounter;
        }
        // Mint tokens to sender
        IAP721(target).mint(sender, quantity);
    }

    /**
     * @notice Facilitates overwrites of token level data storage
     * @dev Overwrites existing data for specified target address + tokenId(s)
     * @param target Target address to store data for
     * @param tokenIds TokenIds to target
     * @param data Data to be stored
     */
    function overwrite(address target, uint256[] memory tokenIds, bytes[] memory data)
        external
        override(AP721DatabaseV1, IAP721Database)
        requireInitialized(target)
    {
        // Prevents users from submitting invalid inputs
        if (tokenIds.length != data.length) {
            revert Invalid_Input_Length();
        }
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Check if tokenId exists
            if (!AP721(payable(target)).exists(tokenIds[i])) revert Token_Does_Not_Exist();
            // Check if sender can overwrite data in target for given tokenId
            if (!IAP721LogicAccess(ap721Settings[target].logic).getOverwriteAccess(target, sender, tokenIds[i])) revert No_Overwrite_Access();
            // Check data is valid
            _validateData(data[i]);
            // Cache storageCounter for tokenId
            uint256 storageCounter = tokenIds[i] - 1;
            // Use sstore2 to store bytes segments
            address newPointer = tokenData[target][storageCounter] = SSTORE2.write(data[i]);
            emit DataOverwritten(target, sender, storageCounter, newPointer);
        }
        // TODO: figure out emitting one event that contains array of storageCounters + newPointers?
    }

    /**
     * @dev When a token is burned, it will return address(0) for its storage pointer
     *      in `readAllData` and will trigger revert in `readData`
     * @param target Target to remove data from
     * @param tokenIds TokenIds to target
     */
    function remove(address target, uint256[] memory tokenIds) external override(AP721DatabaseV1, IAP721Database) requireInitialized(target) {
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i; i < tokenIds.length; ++i) {
            // Check if sender can overwrite data in target for given tokenId
            if (!IAP721LogicAccess(ap721Settings[target].logic).getRemoveAccess(target, sender, tokenIds[i])) revert No_Remove_Access();
            // Cache storageCounter for tokenId
            uint256 storageCounter = tokenIds[i] - 1;
            delete tokenData[target][storageCounter];
            emit DataRemoved(target, sender, storageCounter);
        }
        // TODO: figure out emitting one event that contains array of storageCounters?
        // Burn tokens
        IAP721(target).burnBatch(tokenIds);
    }

    // ////////////////////////////
    // MULTI TARGET
    // ////////////////////////////



    /**
     * @notice Facilitates batch setup of new AP721Proxys in the database
     * @dev Default implementation does not include any checks on if factory is allowed
     * @dev Default implementaton does not provide ability to set fundsRecipient or royaltyBPS
     *      for created AP721
     * @param setupAP721BatchArgs Arguments for batch calling `setupAP721`
     */     
    function setupAP721Batch(SetupAP721BatchArgs[] memory setupAP721BatchArgs) 
        external 
        returns (address[] memory newAP721s) 
    { 
        // Cache for loop length
        uint256 quantity = setupAP721BatchArgs.length;
        // Setup array of addresses to return at the end
        newAP721s = new address[](quantity);

        for (uint256 i; i < quantity; ++i) {
            // Call factory to create + initialize a new AP721Proxy
            address newAP721 = IAP721Factory(setupAP721BatchArgs[i].factory).create(setupAP721BatchArgs[i].initialOwner, setupAP721BatchArgs[i].factoryInit);
            // Decode database init
            (address logic, address renderer, bool transferable, bytes memory logicInit, bytes memory rendererInit)
                = abi.decode(setupAP721BatchArgs[i].databaseInit, (address, address, bool, bytes, bytes));
            // Initialize AP721Proxy in database, This impl only allows for setting of `transferable` in ap721Config
            _setSettings(newAP721, transferable);
            // Set + initialize logic
            _setLogic(newAP721, logic, logicInit);
            // Set + initialize renderer
            _setRenderer(newAP721, renderer, rendererInit);     
            // Emit setup event
            emit SetupAP721({
                ap721: newAP721,
                sender: msg.sender,
                initialOwner: setupAP721BatchArgs[i].initialOwner,
                logic:logic,
                renderer: renderer,
                factory: setupAP721BatchArgs[i].factory
            });                   
            // Store newAP721 address to memory
            newAP721s[i] = newAP721;
        }
        return newAP721s;
    }    

    /**
     * @notice Facilitates token level data storage across multiple targetes
     * @dev Stores data for a specified target addresses and mints storage receipts from those targets to the msg.sender
     * @param storeMultiArgs Arguments for calling `storeMulti`     
     */
    function storeMulti(StoreMultiArgs[] memory storeMultiArgs) external nonReentrant() {
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i; i < storeMultiArgs.length; ++i) {
            // Check if target has been initialized
            if (ap721Settings[storeMultiArgs[i].target].initialized != 1) revert Target_Not_Initialized();

            // Decode token data for target
            bytes[] memory tokens = abi.decode(storeMultiArgs[i].data, (bytes[]));

            // Check if sender can store data in target
            if (!IAP721LogicAccess(ap721Settings[storeMultiArgs[i].target].logic).getStoreAccess(storeMultiArgs[i].target, sender, tokens.length)) {
                revert No_Store_Access();
            }            

            // Store data for each token
            for (uint256 j = 0; j < tokens.length; ++j) {
                // Check data is valid
                _validateData(tokens[j]);
                // Cache storageCounter
                // NOTE: storageCounter trails associated tokenId by 1
                uint256 storageCounter = ap721Settings[storeMultiArgs[i].target].storageCounter;
                // Use sstore2 to store bytes segments
                address pointer = tokenData[storeMultiArgs[i].target][storageCounter] = SSTORE2.write(tokens[j]);
                emit DataStored(
                    storeMultiArgs[i].target,
                    sender,
                    storageCounter, // this trails tokenId associated with storage by 1
                    pointer
                );
                // Increment target storageCounter after storing data
                ++ap721Settings[storeMultiArgs[i].target].storageCounter;
            }
            // Mint tokens to sender
            IAP721(storeMultiArgs[i].target).mint(sender, tokens.length);                 
        }   
    }       

    /**
     * @notice Facilitates overwrites of token level data storage for multiple targets + tokenIds
     * @dev Overwrites existing data for multiple target addresses + tokenId(s)
    * @param overwriteMultiArgs Arguments for calling `overwriteMulti`     
     */
    function overwriteMulti(OverwriteMultiArgs[] memory overwriteMultiArgs) external {
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i; i < overwriteMultiArgs.length; ++i) {
            // Check if target has been initialized
            if (ap721Settings[overwriteMultiArgs[i].target].initialized != 1) revert Target_Not_Initialized();      
            // Prevents users from submitting invalid inputs
            if (overwriteMultiArgs[i].tokenIds.length != overwriteMultiArgs[i].data.length) revert Invalid_Input_Length();

            for (uint256 j = 0; j < overwriteMultiArgs[i].tokenIds.length; ++j) {
                // Check if tokenId exists
                if (!AP721(payable(overwriteMultiArgs[i].target)).exists(overwriteMultiArgs[i].tokenIds[j])) revert Token_Does_Not_Exist();
                // Check if sender can overwrite data in target for given tokenId
                if (
                    !IAP721LogicAccess(
                        ap721Settings[overwriteMultiArgs[i].target].logic
                    ).getOverwriteAccess(
                        overwriteMultiArgs[i].target, sender, overwriteMultiArgs[i].tokenIds[j]
                    )
                ) revert No_Overwrite_Access();
                // Check data is valid
                _validateData(overwriteMultiArgs[i].data[j]);
                // Cache storageCounter for tokenId
                uint256 storageCounter = overwriteMultiArgs[i].tokenIds[j] - 1;
                // Use sstore2 to store bytes segments
                address newPointer = tokenData[overwriteMultiArgs[i].target][storageCounter] = SSTORE2.write(overwriteMultiArgs[i].data[j]);
                emit DataOverwritten(overwriteMultiArgs[i].target, sender, storageCounter, newPointer);
            }
        }        
        // TODO: figure out emitting one event that contains array of storageCounters + newPointers?
    }    

    /**
     * @notice Facilitates removal of token level data storage for multiple targets + tokenIds
     * @dev When a token is burned, it will return address(0) for its storage pointer
     *      in `readAllData` and will trigger revert in `readData`
     * @param removeMultiArgs Arguments for calling `removeMulti`    
     */
    function removeMulti(RemoveMultiArgs[] memory removeMultiArgs) external {
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i; i < removeMultiArgs.length; ++i) {
            // Check if target has been initialized
            if (ap721Settings[removeMultiArgs[i].target].initialized != 1) revert Target_Not_Initialized();     

            for (uint256 j; j < removeMultiArgs[i].tokenIds.length; ++j) {
                // Check if sender can overwrite data in target for given tokenId
                if (!IAP721LogicAccess(ap721Settings[removeMultiArgs[i].target].logic)
                    .getRemoveAccess(removeMultiArgs[i].target, sender, removeMultiArgs[i].tokenIds[j])) revert No_Remove_Access();
                // Cache storageCounter for tokenId
                uint256 storageCounter = removeMultiArgs[i].tokenIds[j] - 1;
                delete tokenData[removeMultiArgs[i].target][storageCounter];
                emit DataRemoved(removeMultiArgs[i].target, sender, storageCounter);
            }
            // TODO: figure out emitting one event that contains array of storageCounters?
            // Burn tokens
            IAP721(removeMultiArgs[i].target).burnBatch(removeMultiArgs[i].tokenIds);
        }
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // ACCESS CHECKS
    //////////////////////////////

    /**
     * @notice Checks storage access for a given target + sender + quantity
     * @param target Target to check access for
     * @param sender Address of sender
     * @param quantity Quantiy to check access for
     * @return access True/false bool
     */
    function canStore(address target, address sender, uint256 quantity)
        external
        view
        requireInitialized(target)
        returns (bool access)
    {
        return IAP721LogicAccess(ap721Settings[target].logic).getStoreAccess(target, sender, quantity);
    }

    /**
     * @notice Checks overwrite access for a given target + sender + tokenId
     * @param target Target to check access for
     * @param sender Address of sender
     * @param tokenId TokenId to check access for
     * @return access True/false bool
     */
    function canOverwrite(address target, address sender, uint256 tokenId)
        external
        view
        requireInitialized(target)
        returns (bool access)
    {
        return IAP721LogicAccess(ap721Settings[target].logic).getOverwriteAccess(target, sender, tokenId);
    }

    /**
     * @notice Checks remove access for a given target + sender + tokenId
     * @param target Target to check access for
     * @param sender Address of sender
     * @param tokenId TokenId to check access for
     * @return access True/false bool
     */
    function canRemove(address target, address sender, uint256 tokenId)
        external
        view
        requireInitialized(target)
        returns (bool access)
    {
        return IAP721LogicAccess(ap721Settings[target].logic).getRemoveAccess(target, sender, tokenId);
    }

    /**
     * @notice Checks settings access for a given target + sender
     * @param target Target to check access for
     * @param sender Address of sender
     * @return access True/false bool
     */
    function canEditSettings(address target, address sender)
        external
        view
        requireInitialized(target)
        returns (bool access)
    {
        return IAP721LogicAccess(ap721Settings[target].logic).getSettingsAccess(target, sender);
    }
}
