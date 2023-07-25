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

import {AP721DatabaseStorageV1} from "./storage/AP721DatabaseStorageV1.sol";
import {AP721} from "../nft/AP721.sol";
import {IAP721} from "../interfaces/IAP721.sol";
import {IAP721Factory} from "../interfaces/IAP721Factory.sol";
import {IAP721Database} from "../interfaces/IAP721Database.sol";
import {IAP721Logic} from "../interfaces/IAP721Logic.sol";
import {IAP721Renderer} from "../interfaces/IAP721Renderer.sol";

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import "sstore2/SSTORE2.sol";

// TODO: should there be a way to store contract level data as well? not just token data?
//      Ex: should things like a contractURI be stored in renderer contracts or in the database?
//      Does this mean that all the store functions need need access checks split out into:
//          canStoreTokenData + canStoreContractData? --- unclear
// TODO: should `readAllData` call return a tokenId alongside the bytes values returned for each slot?
// TODO: add in all of the multi functions
// TODO: confirm if this database impl needs to inherit ERC2771 to enable _msgSender() to be compatible with GSN contracts
//       ^ think we can maybe get rid of this because we'll be using ERC4337 instead?

/**
 * @title AP721DatabaseV1
 * @notice V1 default database architecture
 * @dev Strategy specific databases can inherit this to ensure compatibility with Assembly Press framework
 * @dev All write functions are virtual to allow for modifications
 * @dev This default implementation does not facilitate fees or validity checks for data storage
 * @author Max Bochman
 * @author Salief Lewis
 */
contract AP721DatabaseV1 is AP721DatabaseStorageV1, IAP721Database, ReentrancyGuard {
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

    /**
     * @notice Facilitates setup of a new AP721Proxy in the database
     * @dev Default implementation does not include any checks on if factory is allowed
     * @dev Default implementaton does not provide ability to set fundsRecipient or royaltyBPS
     *      for created AP721
     * @param initialOwner User that will own the AP721Proxy upon deployment
     * @param databaseInit Data to initialize database with
     * @param factory Address of factory to use for AP721Proxy deployment
     * @param factoryInit Data to initialize factory with
     */
    function setupAP721(address initialOwner, bytes memory databaseInit, address factory, bytes memory factoryInit)
        external
        virtual
        nonReentrant
        returns (address)
    {
        // Cache msg.sender
        address sender = msg.sender;
        // Call factory to create + initialize a new AP721Proxy
        address newAP721 = IAP721Factory(factory).create(initialOwner, factoryInit);
        // Decode database init
        (address logic, address renderer, bool transferable, bytes memory logicInit, bytes memory rendererInit) =
            abi.decode(databaseInit, (address, address, bool, bytes, bytes));
        // Initialize AP721Proxy in database
        ap721Settings[newAP721].initialized = 1;
        // Initialize token transferability for AP721Proxy
        ap721Settings[newAP721].ap721Config.transferable = transferable;
        // Set + initialize logic
        _setLogic(newAP721, logic, logicInit);
        // Set + initialize renderer
        _setRenderer(newAP721, renderer, rendererInit);
        // Emit setup event
        emit SetupAP721({
            ap721: newAP721,
            sender: sender,
            initialOwner: initialOwner,
            logic: logic,
            renderer: renderer,
            factory: factory
        });
        // Return address of newly created AP721Proxy
        return newAP721;
    }

    // TODO:
    // multiSetupAP721()

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
    function setLogic(address target, address logic, bytes memory logicInit) external requireInitialized(target) {
        // Request settings access from logic contract
        if (!IAP721Logic(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(target, logic, logicInit);
        emit LogicUpdated(target, logic);
    }

    /**
     * @notice Internal setLogic function
     * @dev No access checks, enforce elsewhere
     * @param target AP721 to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function _setLogic(address target, address logic, bytes memory logicInit) internal {
        ap721Settings[target].logic = logic;
        IAP721Logic(logic).initializeWithData(target, logicInit);
    }

    /**
     * @notice Facilitates updating of renderer contract for a given AP721
     * @dev rendererInit can be blank
     * @param target AP721 to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function setRenderer(address target, address renderer, bytes memory rendererInit)
        external
        requireInitialized(target)
    {
        // Request settings access from renderer contract
        if (!IAP721Logic(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) {
            revert No_Settings_Access();
        }
        // Update + initialize new renderer contract
        _setRenderer(target, renderer, rendererInit);
        emit RendererUpdated(target, renderer);
    }

    /**
     * @notice Internal setRenderer function
     * @dev No access checks, enforce elsewhere
     * @param target AP721 to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function _setRenderer(address target, address renderer, bytes memory rendererInit) internal {
        ap721Settings[target].renderer = renderer;
        IAP721Renderer(renderer).initializeWithData(target, rendererInit);
    }

    // TODO:
    // multiSetLogic()
    // multiSetRenderer()
    // multiSetSettings()?

    //////////////////////////////
    // DATA VALIDATION
    //////////////////////////////

    /**
     * @notice Internal data validation function
     * @dev This database impl does not run any checks on the data. Any data can be stored
     * @param data Data to validate
     */
    function _validateData(bytes memory data) internal view {}

    //////////////////////////////
    // DATA STORAGE
    //////////////////////////////

    /**
     * @notice Facilitates token level data storage
     * @dev Stores data for a specified target address and mints storage receipts from that target to the msg.sender
     * @param target Target address to store data for
     * @param quantity How many storage slots to fill
     * @param data Data to be stored
     */
    function store(address target, uint256 quantity, bytes memory data) external virtual requireInitialized(target) {
        // Cache msg.sender
        address sender = msg.sender;
        // Check if sender can store data in target
        if (!IAP721Logic(ap721Settings[target].logic).getStoreAccess(target, sender, quantity)) {
            revert No_Store_Access();
        }

        // Decode token data
        bytes[] memory tokens = abi.decode(data, (bytes[]));

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
                storageCounter, // this trails tokenId associated with storage by 1
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
        virtual
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
            if (!AP721(payable(target)).exists(tokenIds[i])) {
                revert Token_Does_Not_Exist();
            }
            // Check if sender can overwrite data in target for given tokenId
            if (!IAP721Logic(ap721Settings[target].logic).getOverwriteAccess(target, sender, tokenIds[i])) {
                revert No_Overwrite_Access();
            }
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
    function remove(address target, uint256[] memory tokenIds) external virtual requireInitialized(target) {
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i; i < tokenIds.length; ++i) {
            // Cache storageCounter for tokenId
            uint256 storageCounter = tokenIds[i] - 1;
            // Check if sender can overwrite data in target for given tokenId
            if (!IAP721Logic(ap721Settings[target].logic).getRemoveAccess(target, sender, storageCounter)) {
                revert No_Remove_Access();
            }
            delete tokenData[target][storageCounter];
            emit DataRemoved(target, sender, storageCounter);
        }
        // TODO: figure out emitting one event that contains array of storageCounters?
        // Burn tokens
        IAP721(target).burnBatch(tokenIds);
    }

    // TODO:
    // multiStore()
    // multiOverwrite()
    // multiRemove()
    // multiEverything() ???

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Getter for accessing data for a tokenId from a given target
     * @dev Fetches + returns stored bytes values from sstore2
     * @param target Target address
     * @param tokenId tokenId to retrieve data for
     * @return data Data stored for given token
     */
    function readData(address target, uint256 tokenId)
        external
        view
        requireInitialized(target)
        returns (bytes memory data)
    {
        // Revert lookup if tokenId doesnt exist (not minted or burned)
        if (!AP721(payable(target)).exists(tokenId)) {
            revert Token_Does_Not_Exist();
        }
        // NOTE: tokenData storage trails associated tokenIds by 1
        return SSTORE2.read(tokenData[target][tokenId - 1]);
    }

    /**
     * @notice Getter for accessing data from all tokenIds from a given target
     * @dev Fetches + returns stored bytes values from sstore2
     * @param target Target address
     * @return allData Array of all data stored
     */
    function readAllData(address target) external view requireInitialized(target) returns (bytes[] memory allData) {
        unchecked {
            allData = new bytes[](AP721(payable(target)).lastMintedTokenId());

            for (uint256 i; i < ap721Settings[target].storageCounter; ++i) {
                // Will return bytes(0) if token has been burnt
                allData[i] = SSTORE2.read(tokenData[target][i]);
            }
        }
    }

    /**
     * @notice Getter for accessing settings from a given target
     * @dev Fetches + returns settings information from a given target
     * @param target Target address
     */
    function getSettings(address target) external view returns (IAP721Database.Settings memory) {
        return ap721Settings[target];
    }

    /**
     * @notice Getter for accessing token transferability status from a given target
     * @dev Called by AP721 implementation to determine transferability status
     * @param target Target address
     */
    function getTransferable(address target) external view returns (bool) {
        return ap721Settings[target].ap721Config.transferable;
    }

    //////////////////////////////
    // STATUS CHECKS
    //////////////////////////////

    /**
     * @notice Checks value of initialized variable in ap721Settings mapping for target
     * @param target AP721 contract to check initialization status
     * @return initialized True/false bool if press is initialized
     */
    function isInitialized(address target) external view returns (bool initialized) {
        // Return false if target has not been initialized
        if (ap721Settings[target].initialized == 0) {
            return false;
        }
        return true;
    }

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
        return IAP721Logic(ap721Settings[target].logic).getStoreAccess(target, sender, quantity);
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
        return IAP721Logic(ap721Settings[target].logic).getOverwriteAccess(target, sender, tokenId);
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
        return IAP721Logic(ap721Settings[target].logic).getRemoveAccess(target, sender, tokenId);
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
        return IAP721Logic(ap721Settings[target].logic).getSettingsAccess(target, sender);
    }

    // TODO:
    // figure out if data storage checks need to be seperated
    //      into token level + contract level checks

    //////////////////////////////
    // DATA RENDERING
    //////////////////////////////

    /**
     * @notice ContractURI getter for a given AP721
     * @return uri String contractURI
     */
    function contractURI() public view requireInitialized(msg.sender) returns (string memory uri) {
        return IAP721Renderer(ap721Settings[msg.sender].renderer).getContractURI(msg.sender);
    }

    /**
     * @notice TokenURI getter for a given Press + tokenId
     * @param tokenId TokenId to get uri for
     * @return uri String tokenURI
     */
    function tokenURI(uint256 tokenId) external view requireInitialized(msg.sender) returns (string memory uri) {
        return IAP721Renderer(ap721Settings[msg.sender].renderer).getTokenURI(msg.sender, tokenId);
    }
}
