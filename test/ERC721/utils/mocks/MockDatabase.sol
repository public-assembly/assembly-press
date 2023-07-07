// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721PressDatabase} from "../../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";

import {IERC721Press} from "../../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {ERC721Press} from "../../../../src/core/token/ERC721/ERC721Press.sol";
import {DualOwnable} from "../../../../src/core/utils/ownable/dual/DualOwnable.sol";

import {IERC721PressLogic} from "../../../../src/core/token/ERC721/interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../../../../src/core/token/ERC721/interfaces/IERC721PressRenderer.sol";

import {ERC721PressDatabaseStorageV1} from "../../../../src/core/token/ERC721/database/storage/ERC721PressDatabaseStorageV1.sol";
import {IERC721PressDatabase} from "../../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";

import "sstore2/SSTORE2.sol";

contract MockDatabase is IERC721PressDatabase, ERC721PressDatabaseStorageV1, DualOwnable {

    constructor(address primaryOwner, address secondaryOwner) DualOwnable(primaryOwner, secondaryOwner) {}

    function initializePress(address targetPress) external {
        settingsInfo[msg.sender].initialized = 1;
    }

    function initializeWithData(bytes memory data) external {
        require(data.length > 0, "not zero length ");
    }

    /*
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    rest of mock impl is just there for equivalency. not relevant
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    */

    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////    

    /**
    * @notice Checks if target Press has been initialized to the database
    */
    modifier requireInitialized(address targetPress) {

        if (settingsInfo[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }

        _;
    }            

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // DATABASE ADMIN
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

    /**
    * @notice Getter for officialFactory status of an address. If true, can call `initializePress`
    * @param target Address to check
    */
    function isOfficialFactory(address target) external view returns (bool) {
        if (_officialFactories[target] == true) {
            return true;
        } else {
            return false;
        }
    }        

    //////////////////////////////
    // PRESS SETTINGS
    //////////////////////////////       

    /**
    * @notice Facilitates updating of logic contract for a given Press
    * @dev LogicInit can be blank
    * @param targetPress Press to update logic for
    * @param logic Address of logic implementation
    * @param logicInit Data to init logic with
    */
    function setLogic(address targetPress, address logic, bytes memory logicInit) requireInitialized(targetPress) external {
        // Request settings access from logic contract
        if (IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, msg.sender) == false) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(targetPress, logic, logicInit);
    }  

    /**
    * @notice Facilitates updating of renderer contract for a given Press
    * @dev RendererInit can be blank
    * @param targetPress Press to update renderer for
    * @param renderer Address of renderer implementation
    * @param rendererInit Data to init renderer with
    */
    function setRenderer(address targetPress, address renderer, bytes memory rendererInit) requireInitialized(targetPress) external {
        // Request settings access from logic contract
        if (IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, msg.sender) == false) {
            revert No_Settings_Access();
        }
        // Update + initialize new renderer contract
        _setRenderer(targetPress, renderer, rendererInit);
    }  

    /**
    * @notice Internal handler for setLogic function
    * @dev No access checks, enforce elsewhere
    * @param targetPress Press to update logic for
    * @param logic Address of logic implementation
    * @param logicInit Data to init logic with    
    */
    function _setLogic(address targetPress, address logic, bytes memory logicInit) internal {
        settingsInfo[targetPress].logic = logic;
        IERC721PressLogic(logic).initializeWithData(targetPress, logicInit);

        emit LogicUpdated(targetPress, logic);
    }    

    /**
    * @notice Internal handler for setRenderer function
    * @dev RendererInit can be blank
    * @param targetPress Press to update renderer for
    * @param renderer Address of renderer implementation
    * @param rendererInit Data to init renderer with
    */
    function _setRenderer(address targetPress, address renderer, bytes memory rendererInit) internal {
        settingsInfo[targetPress].renderer = renderer;
        IERC721PressRenderer(renderer).initializeWithData(targetPress, rendererInit);

        emit RendererUpdated(targetPress, renderer);
    }                   

    //////////////////////////////
    // STORE DATA
    //////////////////////////////    

    /**
    * @dev Function called by mintWithData function in ERC721Press mint call that
    *      updates specific tokenData for msg.sender, so no need to add access control to this function
    * @param storeCaller address of account initiating `mintWithData()` from targetPress
    * @param data data getting passed in along mint
    */
    function storeData(address storeCaller, bytes calldata data) external requireInitialized(msg.sender) {
        // Cache msg.sender -- which is the Press if called correctly
        address sender = msg.sender;

        // Cache storedCounter
        // NOTE: storedCounter trails associated tokenId by 1
        uint256 storedCounter = settingsInfo[sender].storedCounter;
        // Use sstore2 to store bytes segments from bytes array                
        idToData[sender][storedCounter] = SSTORE2.write(data);       
        emit DataStored(
            sender, 
            storeCaller,
            storedCounter,  
            idToData[sender][storedCounter]
        );                                       
        // Increment press storedCounter after storing data
        ++settingsInfo[sender].storedCounter;         
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
    function overwriteData(address overwriteCaller, uint256[] memory tokenIds, bytes[] calldata newData) external requireInitialized(msg.sender) {
        // Cache msg.sender
        address targetPress = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {       
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1] = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }              

    //////////////////////////////
    // REMOVE DATA
    //////////////////////////////       

    /**
    * @notice Event emitter that signals for indexer that this token has been burned.
    * @dev When a token is burned, the data associated with it will no longer be returned 
    *     in `getAllData`, and will return zero values in `getData`
    * @param removeCaller address of account initiating `burn` from targetPress
    * @param tokenIds tokenIds to target
    */
    function removeData(address removeCaller, uint256[] memory tokenIds) external requireInitialized(msg.sender) {
        for (uint256 i; i < tokenIds.length; ++i) {
            emit DataRemoved(msg.sender, removeCaller, tokenIds[i]);
        }
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // READ DATA
    //////////////////////////////    

    /**
    * @notice Getter for acessing data for a specific ID for a given Press
    * @dev Fetches + returns stored bytes values from sstore2
    * @param targetPress ERC721Press to target 
    * @param tokenId tokenId to retrieve data for 
    * @return data Data stored for given token
    */
    function readData(address targetPress, uint256 tokenId) 
        external 
        view 
        requireInitialized(targetPress) 
        returns (bytes memory data) {

        // Return blank data if token has been burnt
        if (ERC721Press(payable(targetPress)).exists(tokenId) == false) {
            bytes memory bytesZeroValue = new bytes(0);
            return bytesZeroValue;         
        } else {
            return SSTORE2.read(idToData[targetPress][tokenId-1]);
        }
    }

    /**
    * @notice Getter for acessing data for all active IDs for a given Press
    * @dev Active Ids = Ids whos associated tokens have not been burned
    * @dev Fetches + returns stored bytes values from sstore2
    * @param targetPress ERC721Press to target 
    * @return activeData Array of all active data
    */
    function readAllData(address targetPress) 
        external 
        view 
        requireInitialized(targetPress)
        returns (bytes[] memory activeData) {
        unchecked {
            activeData = new bytes[](ERC721Press(payable(targetPress)).totalSupply());

            // First data slot tokenData mapping is 0
            uint256 activeIndex;

            for (uint256 i; i < settingsInfo[targetPress].storedCounter; ++i) {
                // Skip this listing if user has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(i+1) == false) {
                    continue;
                }
                activeData[activeIndex] =  SSTORE2.read(idToData[targetPress][i]);        
                ++activeIndex;
            }
        }
    } 

    //////////////////////////////
    // PRICE + STATUS CHECKS
    //////////////////////////////           

    /**
    * @notice Checks total mint price for a given Press x mintCaller x mintQuantity
    * @param targetPress Press contract to check mint price of
    * @param mintCaller Address of mintCaller to check pricing on behalf of
    * @param mintQuantity Quantity used to calculate total mint price
    * @return price Total price (in wei) needed to process transaction
    */
    function totalMintPrice(
        address targetPress, 
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (uint256 price) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getMintPrice(targetPress, mintCaller, mintQuantity);
    }         

    /**
    * @notice Checks value of initialized variable in settingsInfo mapping for target Press
    * @param targetPress Press contract to check initialization status
    * @return initialized True/false bool if press is initialized
    */
    function isInitialized(address targetPress) external view returns (bool initialized) {
        // Return false if targetPress has not been initialized
        if (settingsInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }             

    //////////////////////////////
    // ACCESS CHECKS
    //////////////////////////////       

    /**
    * @notice Checks mint access for a given mintQuantity + mintCaller
    * @param targetPress Press contract to check access for
    * @param mintCaller Address of mintCaller to check access for    
    * @param mintQuantity Quantiy to check access for 
    * @return mintAccess True/false bool
    */
    function canMint(
        address targetPress, 
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (bool mintAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getMintAccess(targetPress, mintCaller, mintQuantity);    
    }         

    /**
    * @notice Checks burn access for a given burn caller
    * @param targetPress Press contract to check access for
    * @param burnCaller Address of burnCaller to check access for    
    * @param tokenId TokenId to check access for
    * @return burnAccess True/false bool
    */
    function canBurn(
        address targetPress, 
        address burnCaller,
        uint256 tokenId        
    ) external view requireInitialized(targetPress) returns (bool burnAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getBurnAccess(targetPress, burnCaller, tokenId);            
    }      

    /**
    * @notice Checks settings access for a given settings caller
    * @param targetPress Press contract to check access for
    * @param settingsCaller Address of settingsCaller to check access for 
    * @return settingsAccess True/false bool
    */   
    function canEditSettings(
        address targetPress, 
        address settingsCaller
    ) external view requireInitialized(targetPress) returns (bool settingsAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, settingsCaller);            
    }       

    /**
    * @notice Checks dataCaller edit access for a given edit caller
    * @param targetPress Press contract to check access for
    * @param dataCaller Address of dataCaller to check access for   
    * @return contractAccess True/false bool 
    */
    function canEditContractData(
        address targetPress, 
        address dataCaller
    ) external view requireInitialized(targetPress) returns (bool contractAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getContractDataAccess(targetPress, dataCaller);
    }        

    /**
    * @notice Checks dataCaller edit access for a given edit caller
    * @param targetPress Press contract to check access for
    * @param dataCaller Address of dataCaller to check access for
    * @param tokenId TokenId to check access for     
    * @return tokenAccess True/false bool 
    */   
    function canEditTokenData(
        address targetPress, 
        address dataCaller,
        uint256 tokenId
    ) external view requireInitialized(targetPress) returns (bool tokenAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getTokenDataAccess(targetPress, dataCaller, tokenId);
    }    

    /**
    * @notice Checks payments access for a given caller
    * @param targetPress Press contract to check access for
    * @param paymentsCaller Address of paymentsCaller to check access for   
    * @return paymentsAccess True/false bool     
    */
    function canEditPayments(
        address targetPress, 
        address paymentsCaller
    ) external view requireInitialized(targetPress) returns (bool paymentsAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getPaymentsAccess(targetPress, paymentsCaller);
    }         

    //////////////////////////////
    // DATA RENDERING
    //////////////////////////////   

    /**
    * @notice ContractURI getter for a given Press.
    * @return uri String contractURI
    */
    function contractURI() requireInitialized(msg.sender) external view returns (string memory uri) {
        return IERC721PressRenderer(settingsInfo[msg.sender].renderer).getContractURI(msg.sender);
    }          

    /**
    * @notice TokenURI getter for a given Press + tokenId
    * @param tokenId TokenId to get uri for
    * @return uri String tokenURI
    */
    function tokenURI(uint256 tokenId) requireInitialized(msg.sender) external view returns (string memory uri) {
        return IERC721PressRenderer(settingsInfo[msg.sender].renderer).getTokenURI(msg.sender, tokenId);
    }  
}