// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";
import {DualOwnable} from "../../../utils/ownable/dual/DualOwnable.sol";

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

import {ERC721PressDatabaseStorageV1} from "./storage/ERC721PressDatabaseStorageV1.sol";
import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

import "sstore2/SSTORE2.sol";

/**
* @title ERC721PressDatabaseSkeletonV1
* @notice V1 generic database architecture. Strategy specific databases can inherit this to ensure compatibility with Assembly Press framework
* @dev Contracts that inherit this must implement their own `setOfficialFactory`, `storeData`, `overwriteData` functions 
*       to comply with IERC721PressDatabase interface
* @author Max Bochman
* @author Salief Lewis
*/
abstract contract ERC721PressDatabaseSkeletonV1 is ERC721PressDatabaseStorageV1, IERC721PressDatabase { 

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////    

    /// @notice Shared listing used for final decoded output in Curation strategy.
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * chainId (32) = 32 bytes
     * Second slot
     * tokenId (32) = 32 bytes    
     * Third slot
     * listingAddress (20) + sortOrder (12) = 32 bytes
     */
    struct Listing {
        /// @notice ChainID for curated contract
        uint256 chainId;        
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint256 tokenId;        
        /// @notice Address that is curated
        address listingAddress;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int96 sortOrder;
    }    

    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////    

    /**
    * @notice Checks if target Press has been initialized
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
    * @notice Initializes a Press, giving it the ability to write to database
    * @dev Can only be called by address set as officialFactory
    * @dev Addresses cannot be un-initialized
    * @param targetPress Address of Press to initialize
    */
    function initializePress(address targetPress) external {
        if (_officialFactories[msg.sender] != true) {
            revert No_Initialize_Access();
        }
        settingsInfo[targetPress].initialized = 1;

        emit PressInitialized(msg.sender, targetPress);
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
    // PRESS INITIALIZATION
    //////////////////////////////           

    /**
    * @notice Default logic initializer for a given Press
    * @dev Initializes settings for a given Press
    * @param databaseInit data to init with
    */
    function initializeWithData(bytes memory databaseInit) requireInitialized(msg.sender) external {
        // Cache msg.sender
        address sender = msg.sender;

        // Data format: logic, logicInit, renderer, rendererInit
        (   
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit
        ) = abi.decode(databaseInit, (address, bytes, address, bytes));

        // Set settingsInfo[targetPress]
        settingsInfo[sender].logic = logic;        
        settingsInfo[sender].renderer = renderer;
        
        // Initializes logic + renderer contracts
        _setLogic(sender, logic, logicInit);
        _setRenderer(sender, renderer, rendererInit);                 
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
    // SORT DATA
    //////////////////////////////     

    /**
    * @dev Facilitates z-index style sorting of data IDs. SortOrders can be positive or negative
    * @dev Will only sort ids for a given Press if called directly by the Press
    * @dev Access checks enforced in Press
    * @param sortCaller address of account initiating `sort()` from targetPress 
    * @param tokenIds data IDs to store sortOrders for    
    * @param sortOrders sorting values to store
    */
    function sortData(
        address sortCaller, 
        uint256[] calldata tokenIds, 
        int96[] calldata sortOrders
    ) external requireInitialized(msg.sender) {
        // Cache address of msg.sender -- which will be the targetPress if called correclty
        address targetPress = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; i++) {       
            _sortData(targetPress, tokenIds[i], sortOrders[i]);
        }
        emit DataSorted(targetPress, sortCaller, tokenIds, sortOrders);
    }    
    
    /**
    * @notice Internal handler for sort functionality
    * @dev No access checks, enforce elsewhere
    * @param targetPress address of Press to sort data for
    * @param tokenId TokenId of Press to sort data for
    * @param sortOrder SortOrder value to store
    */
    function _sortData(address targetPress, uint256 tokenId, int96 sortOrder) internal {
        idToData[targetPress][tokenId-1].sortOrder = sortOrder;
    }             

    //////////////////////////////
    // REMOVE DATA
    //////////////////////////////       

    /**
    * @notice Event emitter that signals for indexer that this token has been burned.
    * @dev when a token is burned, the data associated with it will no longer be returned 
    *     in`getAllData`, and will return zero values in `getData`
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
        returns (TokenDataRetrieved memory data) {

        // Return blank struct if token has been burnt
        if (ERC721Press(payable(targetPress)).exists(tokenId) == false) {
            bytes memory bytesZeroValue = new bytes(0);
            return TokenDataRetrieved({
                storedData: bytesZeroValue,
                sortOrder: 0
            });            
        } else {
            return TokenDataRetrieved({
                storedData: SSTORE2.read(idToData[targetPress][tokenId-1].pointer),
                sortOrder: idToData[targetPress][tokenId-1].sortOrder
            });
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
        returns (TokenDataRetrieved[] memory activeData) {
        unchecked {
            activeData = new TokenDataRetrieved[](ERC721Press(payable(targetPress)).totalSupply());

            // First data slot tokenData mapping is 0
            uint256 activeIndex;

            for (uint256 i; i < settingsInfo[targetPress].storedCounter; ++i) {
                // Skip this listing if user has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(i+1) == false) {
                    continue;
                }
                activeData[activeIndex] = TokenDataRetrieved({
                        storedData: SSTORE2.read(idToData[targetPress][i].pointer),
                        sortOrder: idToData[targetPress][i].sortOrder
                });              
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
    * @notice Checks sort access for a given sort caller
    * @param targetPress Press contract to check access for
    * @param sortCaller Address of sortCaller to check access for    
    * @return sortAccess True/false bool
    */
    function canSort(
        address targetPress, 
        address sortCaller
    ) external view requireInitialized(targetPress) returns (bool sortAccess) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getSortAccess(targetPress, sortCaller);            
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