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

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

import {ERC721PressDatabaseStorageV1} from "./storage/ERC721PressDatabaseStorageV1.sol";
import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

import "sstore2/SSTORE2.sol";

/**
* @title ERC721PressDatabaseV1
* @notice ERC721PressDatabaseV1 for AssemblyPress architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract ERC721PressDatabaseV1 is IERC721PressDatabase, ERC721PressDatabaseStorageV1 { 

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (settingsInfo[targetPress].initialized == 0) {
            revert Press_Not_Initialized();
        }

        _;
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE INIT ||||||||||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @dev updates settings for msg.sender, so no need to add access control to this function
    /// @param databaseInit data to init with
    function initializeWithData(bytes memory databaseInit) external {
        address sender = msg.sender;

        // data format: logic, logicInit, renderer, rendererInit
        (   
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit
        ) = abi.decode(databaseInit, (address, bytes, address, bytes));

        // set settingsInfo[targetPress]
        settingsInfo[sender].initialized = 1;
        settingsInfo[sender].logic = logic;        
        settingsInfo[sender].renderer = renderer;
        
        // initialize logic + renderer contracts
        _setLogic(sender, logic, logicInit);
        _setRenderer(sender, renderer, rendererInit);                 
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE ADMIN |||||||||||||
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

    /// @dev Function called by mintWithData function in ERC721Press mint call that
    //      updates specific tokenData for msg.sender, so no need to add access control to this function
    /// @param data data getting passed in along mint
    function storeData(bytes calldata data) external {
        // data format: tokens
        (bytes[] memory tokens) = abi.decode(data, (bytes[]));

        _storeData(msg.sender, tokens);
    }          

    /// @dev Stores indicies of a given bytes array
    /// @param targetPress ERC721Press to target
    /// @param tokens arbitrary encoded bytes data
    function _storeData(address targetPress, bytes[] memory tokens) internal {     
        for (uint256 i = 0; i < tokens.length; ++i) {
            // use sstore2 to store bytes segments in bytes array
            idToData[targetPress][settingsInfo[targetPress].storedCounter].pointer = SSTORE2.write(
                tokens[i]
            );                                
            // increment press storedCounter after storing data
            ++settingsInfo[targetPress].storedCounter;                                
        }           
    }              

    /// @dev Getter for acessing data for a specific ID for a given Press
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve data for 
    function readData(address targetPress, uint256 tokenId) 
        external 
        view 
        requireInitialized(targetPress) 
        returns (TokenDataRetrieved memory) {
        return 
            TokenDataRetrieved({
                storedData: SSTORE2.read(idToData[targetPress][tokenId-1].pointer),
                sortOrder: idToData[targetPress][tokenId-1].sortOrder
            });
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

            // first tokenId minted in ERC721Press impl is #1
            uint256 activeIndex = 1;

            for (uint256 i; i < settingsInfo[targetPress].storedCounter; ++i) {
                // skip this listing if user has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(activeIndex) == false) {
                    continue;
                }
                activeData[activeIndex-1] = TokenDataRetrieved({
                        storedData: SSTORE2.read(idToData[targetPress][i].pointer),
                        sortOrder: idToData[targetPress][i].sortOrder
                });              
                ++activeIndex;
            }
        }
    } 

    // ||||||||||||||||||||||||||||||||
    // ||| SORT FUNCTIONALITY |||||||||
    // ||||||||||||||||||||||||||||||||       

    /// version of function called by calling Press directly
    /// @dev Facilitates z-index style sorting of data IDs. SortOrders can be positive or negative
    /// @dev Will only sort ids for a given Press if called directly by the Press
    /// @dev Access checks enforced in Press
    /// @param sortCaller address of sortCaller    
    /// @param tokenIds data IDs to store sortOrders for    
    /// @param sortOrders sorting values to store
    function sortData(
        address sortCaller, 
        uint256[] calldata tokenIds, 
        int96[] calldata sortOrders
    ) external {
        // Cache address of msg.sender -- which will be the targetPress if called correclty
        (address targetPress) = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; i++) {       
            _sortData(targetPress, tokenIds[i], sortOrders[i]);
        }
        emit DataSorted(targetPress, tokenIds, sortOrders, sortCaller);
    }    

    // /// version of function called by writing directly to database
    // /// @dev Facilitates z-index style sorting of data IDs. SortOrders can be positive or negative
    // /// @param targetPress address of target ERC721Press    
    // /// @param ids data IDs to store sortOrders for    
    // /// @param sortOrders sorting values to store
    // function sortData(
    //     address targetPress, 
    //     uint256[] calldata tokenIds, 
    //     int96[] calldata sortOrders
    // ) external {
        
    //     // checks is sender has access to sort functionality
    //     if (IERC721PressRenderer(settingsInfo[targetPress].logic).getSortAccess(targetPress, msg.sender) == false) {
    //         revert No_Sort_Access();
    //     }

    //     // prevents users from submitting invalid inputs
    //     if (tokenIds.length != sortOrders.length) {
    //         revert Invalid_Input_Length();
    //     }

    //     for (uint256 i = 0; i < tokenIds.length; i++) {       
    //         _sortData(targetPress, tokenIds[i], sortOrders[i]);
    //     }
    //     emit DataSorted(targetPress, tokenIds, sortOrders, msg.sender);
    // }
    
    /// @notice Internal handler for sort functionality
    /// @dev No access checks, enforce elsewhere
    function _sortData(address targetPress, uint256 tokenId, int96 sortOrder) internal {
        //
        idToData[targetPress][tokenId].sortOrder = sortOrder;
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
    /// @dev `tokenId` is unused, but present to adhere to the interface requirements of IERC721PressDatabase
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