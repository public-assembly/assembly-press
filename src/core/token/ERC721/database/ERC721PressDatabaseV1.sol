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

import {ILogic} from "../core/logic/ILogic.sol";

import {ERC721DatabaseStorageV1} from "../storage/ERC721DatabaseStorageV1.sol";
import {IDatabaseEngine} from "../interfaces/IDatabaseEngine.sol";

import "sstore2/SSTORE2.sol";

/**
* @title ERC721PressDatabase
* @notice ERC721PressDatabase for AssemblyPress architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract ERC721PressDatabase is IERC721PressDatabase, IDatabseLogic, ERC721DatabaseStorageV1 { 

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (configInfo[targetPress].initialized == 0) {
            revert Press_Not_Initialized();
        }

        _;
    }            

    /// @notice Modifier that ensures database functionality is active and not frozen
    ///     and that msg.sender is not the admin
    modifier onlyActive(address targetPress) {
        if (
            configInfo[targetPress].isPaused && 
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
        ) {
            revert DATABASE_PAUSED();
        }

        if (configInfo[targetPress].frozenAt != 0 && configInfo[targetPress].frozenAt < block.timestamp) {
            revert DATABASE_FROZEN();
        }

        _;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CONTROL CHECKS ||||||
    // ||||||||||||||||||||||||||||||||   

    /// @notice checks update access for a given update caller
    /// @param targetPress press contract to check access for
    /// @param updateCaller address of updateCaller to check access for
    function canUpdateConfig(
        address targetPress, 
        address updateCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        // check if update caller has admin role for given Press
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, updateCaller) < ADMIN
        ) { 
            return false;
        }

        return true;
    }                  

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    /// @dev `mintQuantity` is unused, but present to adhere to the interface requirements of IERC721PressDatabase
    function canMint(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) onlyActive(targetPress)  returns (bool) {
        // check if mint caller has minter role for given Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, mintCaller) < USER) { 
            return false;
        }        

        return true;
    }              

    /// @notice checks metadata edit access for a given edit caller
    /// @param targetPress press contract to check access for
    /// @param editCaller address of editCaller to check access for
    function canEditMetadata(
        address targetPress, 
        address editCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        // check if edit caller has edit role for given Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, editCaller) < MANAGER) { 
            return false;
        }        

        return true;
    }           

    /// @notice checks funds withdrawl access for a given withdrawal caller
    /// @param targetPress press contract to check access for
    /// @param withdrawCaller address of withdrawCaller to check access for
    function canWithdraw(
        address targetPress, 
        address withdrawCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        // check if withdraw caller has anyone role for given Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, withdrawCaller) < ANYONE) { 
            return false;
        }  

        return true;
    }                   

    /// @notice checks burn access for a given burn caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param burnCaller address of burnCaller to check access for
    /// @dev `tokenId` is unused, but present to adhere to the interface requirements of IERC721PressDatabase
    function canBurn(
        address targetPress, 
        uint256 tokenId,
        address burnCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        // check if burnCaller has burn access for given target Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, burnCaller) < ADMIN) {
            return false;
        }

        return true;
    }               

    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks value of initialized variable in configInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {
        // return false if targetPress has not been initialized
        if (configInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }       

    /// @notice checks value of isPaused variable in configInfo mapping for target Press
    /// @param targetPress press contract to check pause status
    function isPaused(address targetPress) external view returns (bool) {
        // return bool state of isPaused variable
        return configInfo[targetPress].isPaused;
    }       

    /// @notice checks total mint price for a given mintQuantity x mintCaller
    /// @param targetPress press contract to check mint price of
    /// @param mintQuantity mintQuantity used to calculate total mint price
    /// @param mintCaller address of mintCaller to check pricing on behalf of
    function totalMintPrice(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) returns (uint256) {
        // There is no fee (besides gas) to store a listing
        return configInfo[targetPress].accessControl.getMintPrice(targetPress, mintCaller, mintQuantity);
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC INIT |||||||||||||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        address sender = msg.sender;
        // data format: initialPause, accessControl, accessControlInit
        (   
            bool initialPause,
            IAccessControl accessControl,
            bytes memory accessControlInit
        ) = abi.decode(logicInit, (bool, IAccessControl, bytes));

        // set configInfo[targetPress]
        configInfo[sender].initialized = 1;
        configInfo[sender].isPaused = initialPause;
        configInfo[sender].accessControl = accessControl;
        // initialize access control
        accessControl.initializeWithData(sender, accessControlInit);   

        emit SetAccessControl(sender, accessControl);                   
    }         

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC STORAGE ||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// @dev Function called by mintWithData function in ERC721Press mint call that
    //      updates Press specific listings mapping in ERC721DatabaseStorageV1
    /// @param data data getting passed in along mint
    function storeData(bytes calldata data) external {

        // data: listings
        (bytes[] memory listings) = abi.decode(data, (bytes[]));

        _addListings(msg.sender, listings);
    }          

    /// @dev Stores sliced bytes section (containing listing info)
    /// @param targetPress ERC721Press to target
    /// @param listings Listing structs encoded bytes
    function _addListings(address targetPress, bytes[] memory listings) internal {     

        for (uint256 i = 0; i < listings.length; ++i) {
            // use sstore2 to store bytes segments in bytes array
            idToListing[targetPress][configInfo[targetPress].numAdded] = SSTORE2.write(
                listings[i]
            );    
            ++configInfo[targetPress].numAdded;                        
        }           
    }              

    // previous version
    // /// @dev Function called by mintWithData function in ERC721Press mint call that
    // //      updates Press specific listings mapping in ERC721DatabaseStorageV1
    // /// @param data data getting passed in along mint
    // function storeData(bytes calldata data) external {

    //     // check that input data is of expected length
    //     //      prevents unnamed reverts in array slicing operations
    //     //      LISTING_SIZE is constant found in ERC721DatabaseStorageV1
    //     if (data.length % LISTING_SIZE != 0) {
    //         revert Invalid_Input_Data_Length();
    //     }

    //     _addListings(msg.sender, data);
    // }         

    // previous version
    // /// @dev Stores sliced bytes section (containing listing info)
    // /// @param targetPress ERC721Press to target
    // /// @param listings Listing structs encoded bytes
    // function _addListings(address targetPress, bytes calldata listings) internal {     

    //     // calculate number of listings
    //     uint256 numListings = listings.length / LISTING_SIZE;

    //     // slice the bytes section relevant for each listing and pass it to _addListing function
    //     for (uint256 i; i < numListings; ++i) {
    //         // find starting index for array slice
    //         uint256 sliceStart = i * LISTING_SIZE;
    //         // use sstore2 to store specific segment of bytes encoded listings 
    //         idToListing[targetPress][configInfo[targetPress].numAdded] = SSTORE2.write(
    //             listings[sliceStart: sliceStart + LISTING_SIZE]
    //         );    
    //         ++configInfo[targetPress].numAdded;              
    //     }                 
    // }           

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve Listing info for 
    function getListing(address targetPress, uint256 tokenId) external view override returns (Listing memory) {
        return _bytesToListing(SSTORE2.read(idToListing[targetPress][tokenId-1]));
    }

    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListings(address targetPress) external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](configInfo[targetPress].numAdded - configInfo[targetPress].numRemoved);

            // first tokenId minted in ERC721Press impl is #1
            uint256 activeIndex = 1;

            for (uint256 i; i < configInfo[targetPress].numAdded; ++i) {
                // skip this listing if user has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(activeIndex) != true) {
                    continue;
                }
                activeListings[activeIndex-1] = _bytesToListing(SSTORE2.read(idToListing[targetPress][i]));
                ++activeIndex;
            }
        }
    } 

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC ADMIN ||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @dev Allows contract owner to update the ERC721 Database Pass being used to restrict access to database functionality
    /// @param targetPress address of Press to target
    /// @param setPaused boolean of new database active state
    function setDatabasePaused(address targetPress, bool setPaused) external {
        // Checks role of msg.sender for access
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert No_Pause_Access();
        }
        // Prevents owner from updating the database active state to the current active state
        if (configInfo[targetPress].isPaused == setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setDatabasePaused(targetPress, setPaused);
    }

    // internal handler for setDatabasePaused function
    function _setDatabasePaused(address targetPress, bool _setPaused) internal {
        configInfo[targetPress].isPaused = _setPaused;

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
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert No_Freeze_Access();
        }

        // Prevents owner from adjusting freezeAt time if contract alrady frozen
        if (configInfo[targetPress].frozenAt != 0 && configInfo[targetPress].frozenAt < block.timestamp) {
            revert DATABASE_FROZEN();
        }
        // update frozen at value
        configInfo[targetPress].frozenAt = timestamp;
        emit ScheduledFreeze(targetPress, timestamp);
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