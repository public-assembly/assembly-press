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

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (settingsInfo[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }

        _;
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE ADMIN |||||||||||||
    // ||||||||||||||||||||||||||||||||     

    function setOfficialFactory(address factory) eitherOwner external {
        _officialFactories[factory] = true;
        emit NewFactoryAdded(msg.sender, factory);
    }

    // NOTE: Removed from Mock
    // function initializePress(address targetPress) external {
    //     if (_officialFactories[msg.sender] != true) {
    //         revert No_Initialize_Access();
    //     }
    //     settingsInfo[targetPress].initialized = 1;

    //     emit PressInitialized(msg.sender, targetPress);
    // }

    function isOfficialFactory(address target) external {
        if (_officialFactories[target] == true) {
            true;
        } else {
            false;
        }
    }

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE PRESS INIT ||||||||
    // ||||||||||||||||||||||||||||||||          

    // NOTE: Removed from Mock
    // /// @notice Default logic initializer for a given Press
    // /// @dev updates settings for msg.sender, so no need to add access control to this function
    // /// @param databaseInit data to init with
    // function initializeWithData(bytes memory databaseInit) requireInitialized(msg.sender) external {

    //     // Cache msg.sender
    //     address sender = msg.sender;

    //     // data format: logic, logicInit, renderer, rendererInit
    //     (   
    //         address logic,
    //         bytes memory logicInit,
    //         address renderer,
    //         bytes memory rendererInit
    //     ) = abi.decode(databaseInit, (address, bytes, address, bytes));

    //     // set settingsInfo[targetPress]
    //     settingsInfo[sender].logic = logic;        
    //     settingsInfo[sender].renderer = renderer;
        
    //     // initialize logic + renderer contracts
    //     _setLogic(sender, logic, logicInit);
    //     _setRenderer(sender, renderer, rendererInit);                 
    // }       

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE PRESS ADMIN |||||||
    // ||||||||||||||||||||||||||||||||     

    // external handler for setLogic function
    function setLogic(address targetPress, address logic, bytes memory logicInit) requireInitialized(targetPress) external {
        // Check if msg.sender has access to update settings for Press
        if (IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, msg.sender) == false) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(targetPress, logic, logicInit);
    }  

    // external handler for setRenderer function
    function setRenderer(address targetPress, address renderer, bytes memory rendererInit) requireInitialized(targetPress) external {
        if (IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, msg.sender) == false) {
            revert No_Settings_Access();
        }
        // Update + initialize new renderer contract
        _setRenderer(targetPress, renderer, rendererInit);
    }  

    /// @notice internal handler for setLogic function
    /// @dev no access checks, enforce elsewhere
    function _setLogic(address targetPress, address logic, bytes memory logicInit) internal {
        settingsInfo[targetPress].logic = logic;
        IERC721PressLogic(logic).initializeWithData(targetPress, logicInit);

        emit LogicUpdated(targetPress, logic);
    }    

    /// @notice internal handler for setRenderer function
    /// @dev no access checks, enforce elsewhere
    function _setRenderer(address targetPress, address renderer, bytes memory rendererInit) internal {
        settingsInfo[targetPress].renderer = renderer;
        IERC721PressRenderer(renderer).initializeWithData(targetPress, rendererInit);

        emit RendererUpdated(targetPress, renderer);
    }          

    // ||||||||||||||||||||||||||||||||
    // ||| DATA STORAGE |||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /////////////////////////
    // WRITE
    /////////////////////////    

    /// @dev Function called by mintWithData function in ERC721Press mint call that
    //      updates specific tokenData for msg.sender, so no need to add access control to this function
    /// @param storeCaller address of account initiating `mintWithData()` from targetPress
    /// @param data data getting passed in along mint
    function storeData(address storeCaller, bytes calldata data) external requireInitialized(msg.sender) {
        // data format: tokens
        (bytes[] memory tokens) = abi.decode(data, (bytes[]));

        _storeData(msg.sender, storeCaller, tokens);
    }          

    /// @dev Stores indicies of a given bytes array
    /// @param targetPress ERC721Press to target
    /// @param storeCaller address of account initiating `mintWithData` from targetPress
    /// @param tokens arbitrary encoded bytes data
    function _storeData(address targetPress, address storeCaller, bytes[] memory tokens) internal {     
        for (uint256 i = 0; i < tokens.length; ++i) {
            // cache storedCounter
            uint256 storedCounter = settingsInfo[targetPress].storedCounter;
            // use sstore2 to store bytes segments in bytes array
            idToData[targetPress][storedCounter].pointer = SSTORE2.write(
                tokens[i]
            );       
            // NOTE: storedCounter trails the tokenId being minted by 1
            emit DataStored(
                targetPress, 
                storeCaller,
                storedCounter,  
                idToData[targetPress][storedCounter].pointer
            );                                       
            // increment press storedCounter after storing data
            ++settingsInfo[targetPress].storedCounter;    
        }           
    }              

    /// @dev Facilitates z-index style sorting of data IDs. SortOrders can be positive or negative
    /// @dev Will only sort ids for a given Press if called directly by the Press
    /// @dev Access checks enforced in Press
    /// @param sortCaller address of account initiating `sort()` from targetPress 
    /// @param tokenIds data IDs to store sortOrders for    
    /// @param sortOrders sorting values to store
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
    
    /// @notice Internal handler for sort functionality
    /// @dev No access checks, enforce elsewhere
    function _sortData(address targetPress, uint256 tokenId, int96 sortOrder) internal {
        //
        idToData[targetPress][tokenId-1].sortOrder = sortOrder;
    }        

    /// @dev Updates sstore2 data ointers for already existing tokens
    /// @param overwriteCaller address of account initiating `update()` from targetPress
    /// @param tokenIds arbitrary encoded bytes data
    /// @param newData data passed in alongside update call
    function overwriteData(address overwriteCaller, uint256[] memory tokenIds, bytes[] calldata newData) external requireInitialized(msg.sender) {
        // Cache msg.sender
        address targetPress = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1].pointer = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }             

    /// @dev Event emitter that signals for indexer that this token has been burned.
    ///     when a token is burned, the data associated with it will no longer be returned 
    ///     in`getAllData`, and will return zero values in `getData`
    /// @param removeCaller address of account initiating `burn` from targetPress
    /// @param tokenIds tokenIds to target
    function removeData(address removeCaller, uint256[] memory tokenIds) external requireInitialized(msg.sender) {
        for (uint256 i; i < tokenIds.length; ++i) {
            emit DataRemoved(msg.sender, removeCaller, tokenIds[i]);
        }
    }    

    /////////////////////////
    // READ
    /////////////////////////    

    /// @dev Getter for acessing data for a specific ID for a given Press
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve data for 
    function readData(address targetPress, uint256 tokenId) 
        external 
        view 
        requireInitialized(targetPress) 
        returns (TokenDataRetrieved memory) {

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

    /// @dev Getter for acessing data for all active IDs for a given Press
    /// @param targetPress ERC721Press to target     
    function readAllData(address targetPress) 
        external 
        view 
        requireInitialized(targetPress)
        returns (TokenDataRetrieved[] memory activeData) {
        unchecked {
            activeData = new TokenDataRetrieved[](ERC721Press(payable(targetPress)).totalSupply());

            // first data slot tokenData mapping is 0
            uint256 activeIndex;

            for (uint256 i; i < settingsInfo[targetPress].storedCounter; ++i) {
                // skip this listing if user has burned the token (sent to zero address)
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
  
    // ||||||||||||||||||||||||||||||||
    // ||| PRICE + STATUS CHECKS ||||||
    // ||||||||||||||||||||||||||||||||     

    /// @notice checks total mint price for a given Press x mintCaller x mintQuantity
    /// @param targetPress press contract to check mint price of
    /// @param mintCaller address of mintCaller to check pricing on behalf of
    /// @param mintQuantity mintQuantity used to calculate total mint price
    function totalMintPrice(
        address targetPress, 
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (uint256) {
        return IERC721PressLogic(settingsInfo[targetPress].logic).getMintPrice(targetPress, mintCaller, mintQuantity);
    }         

    /// @notice checks value of initialized variable in settingsInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {
        // return false if targetPress has not been initialized
        if (settingsInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }             

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintCaller address of mintCaller to check access for    
    /// @param mintQuantity mintQuantity to check access for 
    function canMint(
        address targetPress, 
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (bool) {
        //        
        return IERC721PressLogic(settingsInfo[targetPress].logic).getMintAccess(targetPress, mintCaller, mintQuantity);    
    }         

    /// @notice checks burn access for a given burn caller
    /// @param targetPress press contract to check access for
    /// @param burnCaller address of burnCaller to check access for    
    /// @param tokenId tokenId to check access for
    function canBurn(
        address targetPress, 
        address burnCaller,
        uint256 tokenId        
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getBurnAccess(targetPress, burnCaller, tokenId);            
    }     

    /// @notice checks sort access for a given sort caller
    /// @param targetPress press contract to check access for
    /// @param sortCaller address of sortCaller to check access for    
    function canSort(
        address targetPress, 
        address sortCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getSortAccess(targetPress, sortCaller);            
    }     

    /// @notice checks settings access for a given settings caller
    /// @param targetPress press contract to check access for
    /// @param settingsCaller address of settingsCaller to check access for    
    function canEditSettings(
        address targetPress, 
        address settingsCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getSettingsAccess(targetPress, settingsCaller);            
    }       

    /// @notice checks dataCaller edit access for a given edit caller
    /// @param targetPress press contract to check access for
    /// @param dataCaller address of dataCaller to check access for    
    function canEditContractData(
        address targetPress, 
        address dataCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getContractDataAccess(targetPress, dataCaller);
    }        

    /// @notice checks dataCaller edit access for a given edit caller
    /// @param targetPress press contract to check access for
    /// @param dataCaller address of dataCaller to check access for
    /// @param tokenId tokenId to check access for        
    function canEditTokenData(
        address targetPress, 
        address dataCaller,
        uint256 tokenId
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getTokenDataAccess(targetPress, dataCaller, tokenId);
    }    

    /// @notice checks payments access for a given caller
    /// @param targetPress press contract to check access for
    /// @param paymentsCaller address of paymentsCaller to check access for   
    function canEditPayments(
        address targetPress, 
        address paymentsCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return IERC721PressLogic(settingsInfo[targetPress].logic).getPaymentsAccess(targetPress, paymentsCaller);
    }         

    // ||||||||||||||||||||||||||||||||
    // ||| METADATA RENDERING |||||||||
    // ||||||||||||||||||||||||||||||||  

    function contractURI() requireInitialized(msg.sender) external view returns (string memory) {
        return IERC721PressRenderer(settingsInfo[msg.sender].renderer).getContractURI(msg.sender);
    }          

    function tokenURI(uint256 tokenId) requireInitialized(msg.sender) external view returns (string memory) {
        return IERC721PressRenderer(settingsInfo[msg.sender].renderer).getTokenURI(msg.sender, tokenId);
    }              
}