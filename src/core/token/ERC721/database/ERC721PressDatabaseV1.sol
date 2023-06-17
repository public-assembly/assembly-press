// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";

import {ILogic} from "../logic/ILogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

import {ERC721PressDatabaseStorageV1} from "./storage/ERC721PressDatabaseStorageV1.sol";
import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

import "sstore2/SSTORE2.sol";

/**
* @title ERC721PressDatabase
* @notice ERC721PressDatabase for AssemblyPress architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract ERC721PressDatabase is IERC721PressDatabase, ERC721PressDatabaseStorageV1 { 

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

    /// @notice Modifier that ensures database functionality is active and not frozen
    ///     and that msg.sender is not the admin
    modifier onlyActive(address targetPress) {
        
        // Check if Press database is frozen
        if (settingsInfo[targetPress].frozenAt != 0 && settingsInfo[targetPress].frozenAt < block.timestamp) {
            revert DATABASE_FROZEN();
        }

        // Check if Press database is paused
        if (
            settingsInfo[targetPress].isPaused && 
            settingsInfo[targetPress].logic.getPauseAccess(targetPress, msg.sender) == false
        ) {
            revert DATABASE_PAUSED();
        }        

        _;
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE INIT ||||||||||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param databaseInit data to init with
    function initializeWithData(bytes memory databaseInit) external {
        address sender = msg.sender;
        // data format: logic, logicInit, renderer, rendererInit, initialPause
        (   
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit,
            uint80 priceToStore,
            bool initialPause,
        ) = abi.decode(databaseInit, (ILogic, bool, IAccessControl, bytes));

        // set settingsInfo[targetPress]
        settingsInfo[sender].initialized = 1;
        settingsInfo[sender].logic = logic;        
        settingsInfo[sender].isPaused = initialPause;
        settingsInfo[sender].renderer = renderer;
        
        // initialize logic + renderer contracts
        ILogic(logic).initializeWithData(sender, logicInit);   
        IERC721PressRenderer(renderer).initializeWithData(sender, rendererInit);   

        emit SetupNewPress(sender, logic, renderer);                   
    }         

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE STORAGE |||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// @dev Function called by mintWithData function in ERC721Press mint call that
    //      updates Press specific tokenData mapping in ERC721DatabaseStorageV1
    /// @param data data getting passed in along mint
    function storeData(bytes calldata data) external {
        // data format: chunks
        (bytes[] memory chunks) = abi.decode(data, (bytes[]));

        _storeData(msg.sender, chunks);
    }          

    /// @dev Stores indicies of a given bytes array
    /// @param targetPress ERC721Press to target
    /// @param chunks arbitrary encoded bytes data
    function _storeData(address targetPress, bytes[] memory chunks) internal {     
        for (uint256 i = 0; i < chunks.length; ++i) {
            // use sstore2 to store bytes segments in bytes array
            idToData[targetPress][settingsInfo[targetPress].storedCounter] = SSTORE2.write(
                chunks[i]
            );    
            ++settingsInfo[targetPress].storedCounter;                        
        }           
    }              

    /// @dev Getter for acessing data for a specific ID for a given Press
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve data for 
    function getData(address targetPress, uint256 tokenId) external view override returns (bytes memory) {
        return SSTORE2.read(idToListing[targetPress][tokenId-1]);
    }

    /// @dev Getter for acessing data for all active IDs for a given Press
    /// @param targetPress ERC721Press to target     
    function getAllData(address targetPress) external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeData = new bytes[](ERC721Press(payable(targetPress)).totalSupply());

            // first tokenId minted in ERC721Press impl is #1
            uint256 activeIndex = 1;

            for (uint256 i; i < settingsInfo[targetPress].numAdded; ++i) {
                // skip this listing if user has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(activeIndex) != true) {
                    continue;
                }
                activeData[activeIndex-1] = SSTORE2.read(idToListing[targetPress][i]);
                ++activeIndex;
            }
        }
    } 

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE ADMIN |||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// TODO: write update logic file + update renderer file impls
    ///     using getSettings access checks
    ///
    ///
    ///

    /// @dev Allows contract owner to update the ERC721 Database Pass being used to restrict access to database functionality
    /// @param targetPress address of Press to target
    /// @param setPaused boolean of new database active state
    function setDatabasePaused(address targetPress, bool setPaused) external {
        // Checks role of msg.sender for access
        if (
            settingsInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert No_Pause_Access();
        }
        // Prevents owner from updating the database active state to the current active state
        if (settingsInfo[targetPress].isPaused == setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setDatabasePaused(targetPress, setPaused);
    }

    // internal handler for setDatabasePaused function
    function _setDatabasePaused(address targetPress, bool _setPaused) internal {
        settingsInfo[targetPress].isPaused = _setPaused;

        emit DatabasePauseUpdated(msg.sender, targetPress, _setPaused);
    }

    /// @dev Allows owner or user to store Listings --> which mints listingRecords to the msg.sender
    /// @param targetPress address of target ERC721Press    
    /// @param tokenIds listingRecords to update SortOrders for    
    /// @param sortOrders sortOrders to update existing listingRecords
    function updateSortOrders(
        address targetPress, 
        uint256[] calldata tokenIds, 
        int32[] calldata sortOrders
    ) external onlyActive(targetPress) {
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert Invalid_Input_Length();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // prevents non-owners from updating the SortOrder on a listingRecord they did not stores themselves 
            if (ERC721Press(payable(address(targetPress))).ownerOf(tokenIds[i]) != msg.sender) {
                revert No_SortOrder_Access();
            }          
            _setSortOrder(targetPress, tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(targetPress, tokenIds, sortOrders, msg.sender);
    }

    // prevents non-owners from updating the SortOrder on a listingRecord they did not store themselves 
    function _setSortOrder(address targetPress, uint256 listingId, int32 sortOrder) internal {
        
        // convert listing bytes to listing struct and cache
        Listing memory tempListing = _bytesToListing(SSTORE2.read(idToListing[targetPress][listingId]));

        // update sort order value of listing
        tempListing.sortOrder = sortOrder;

        // re encode listing struct to bytes and store
        idToListing[targetPress][listingId] = SSTORE2.write(_listingToBytes(tempListing));
    }

    /// @dev Allows contract owner to freeze all add/sort functionality starting from a given Unix timestamp
    /// @param targetPress ERC721Press to target
    /// @param timestamp unix timestamp in seconds
    function freezeAt(address targetPress, uint256 timestamp) external {

        if (
            settingsInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert No_Freeze_Access();
        }

        // Prevents owner from adjusting freezeAt time if contract alrady frozen
        if (settingsInfo[targetPress].frozenAt != 0 && settingsInfo[targetPress].frozenAt < block.timestamp) {
            revert DATABASE_FROZEN();
        }
        // update frozen at value
        settingsInfo[targetPress].frozenAt = timestamp;
        emit ScheduledFreeze(targetPress, timestamp);
    }  

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS + PRICE CHECKS ||||||
    // ||||||||||||||||||||||||||||||||   

    /// @notice checks total mint price for a given mintQuantity x mintCaller
    /// @param targetPress press contract to check mint price of
    /// @param mintQuantity mintQuantity used to calculate total mint price
    /// @param mintCaller address of mintCaller to check pricing on behalf of
    function totalMintPrice(
        address targetPress, 
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (uint256) {
        // There is no fee (besides gas) to store a listing
        return settingsInfo[targetPress].ILogic(logic).getMintPrice(targetPress, mintCaller, mintQuantity);
    }   

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintCaller address of mintCaller to check access for    
    /// @param mintQuantity mintQuantity to check access for 
    /// @dev `mintQuantity` is unused, but present to adhere to the interface requirements of IERC721PressDatabase
    function canMint(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) onlyActive(targetPress)  returns (bool) {
        //        
        return settingsInfo[targetPress].ILogic(logic).getMintAccess(targetPress, mintCaller, mintQuantity);    
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
        return settingsInfo[targetPress].ILogic(logic).getBurnAccess(targetPress, burnCaller, tokenId);            
    }     

    /// @notice checks sort access for a given sort caller
    /// @param targetPress press contract to check access for
    /// @param sortCaller address of sortCaller to check access for    
    function canSort(
        address targetPress, 
        address sortCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return settingsInfo[targetPress].ILogic(logic).getSortAccess(targetPress, sortCaller);            
    }    

    /// TODO: write can updateSettings (logic + renderer) checks
    ///     will be consumed by other local function in 
    ///     database admin section
    ///
    ///

    /// @notice checks metadata edit access for a given edit caller
    /// @param targetPress press contract to check access for
    /// @param metadataCaller address of metadataCaller to check access for
    /// @param tokenId tokenId to check access for        
    function canEditMetadata(
        address targetPress, 
        address metadataCaller,
        uint256 tokenId
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return settingsInfo[targetPress].ILogic(logic).getMetadataAccess(targetPress, metadataCaller, tokenId);
    }    

    /// @notice checks payments access for a given caller
    /// @param targetPress press contract to check access for
    /// @param paymentsCaller address of paymentsCaller to check access for   
    function canEditPayments(
        address targetPress, 
        address paymentsCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        //
        return settingsInfo[targetPress].ILogic(logic).getPaymentsAccess(targetPress, metadataCaller, tokenId);
    }    
                
    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks value of initialized variable in settingsInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {
        // return false if targetPress has not been initialized
        if (settingsInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }       

    /// @notice checks value of isPaused variable in settingsInfo mapping for target Press
    /// @param targetPress press contract to check pause status
    function isPaused(address targetPress) external view returns (bool) {
        // return bool state of isPaused variable
        return settingsInfo[targetPress].isPaused;
    }       

    /// @notice Check if database for given Press is frozen
    /// @param targetPress press contract to check frozen status
    function isFrozen(address targetPress) external view returns (bool) {
        // Check if Press database is frozen
        if (settingsInfo[targetPress].frozenAt != 0 && settingsInfo[targetPress].frozenAt < block.timestamp) {
            return true;
        } else {
            return false;
        }        
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| HELPERS ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev Decodes stored bytes values and assembles it into Listing sturct
    /// @param data data to process
    function _bytesToListing(bytes memory data) internal view returns (Listing memory) {
        // data format: chainId, tokenId, listingAddress, sortOrder, hasTokenId
        (
            uint16 chainId, 
            uint96 tokenId, 
            address listingAddress, 
            int32 sortOrder, 
            bool hasTokenId
        ) = abi.decode(data, (uint16, uint96, address, int32, bool));

        return 
            Listing({
                chainId: chainId,
                tokenId: tokenId,
                listingAddress: listingAddress,
                sortOrder: sortOrder,
                hasTokenId: hasTokenId
            });
    }

    /// @dev Encode Listing struct into bytes
    /// @param listing lisging to process
    function _listingToBytes(Listing memory listing) internal pure returns (bytes memory) {
        return abi.encode(
            listing.chainId,
            listing.tokenId,
            listing.listingAddress,
            listing.hasTokenId,
            listing.sortOrder
        );   
    }        
}