// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";
import {CurationStorageV1} from "./CurationStorageV1.sol";
import {ICurationLogic} from "./ICurationLogic.sol";
// import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";
import {IAccessControlRegistry} from "../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

/**
* @title ERC721Press
* @notice CurationLogic for AssemblyPress architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract CurationLogic is IERC721PressLogic, ICurationLogic, CurationStorageV1 { 

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

    /// @notice Checks if msg.sender has admin level privileges for given Press contract
    modifier requireSenderAdmin(address targetPress, address senderToCheck) {

        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, senderToCheck) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert Not_Admin();
        }

        _;
    }                

    /// @notice Modifier that ensures curation functionality is active and not frozen
    ///     and that msg.sender is not the admin
    modifier onlyActive(address targetPress) {
        if (
            configInfo[targetPress].isPaused && 
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
        ) {
            revert CURATION_PAUSED();
        }

        if (configInfo[targetPress].frozenAt != 0 && configInfo[targetPress].frozenAt < block.timestamp) {
            revert CURATION_FROZEN();
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
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            return false;
        }

        return true;
    }                  

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    function canMint(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) onlyActive(targetPress) returns (bool) {
        // check if mint caller has minter role for given Press
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, mintCaller) < CURATOR
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            return false;
        }        
        // check if mintQuantity + mintCaller are valid inputs
        if (mintQuantity == 0 || mintCaller == address(0)) {
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
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, editCaller) < MANAGER
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
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
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, withdrawCaller) < ANYONE
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            return false;
        }  

        return true;
    }                   

    /// @notice checks upgrade access for a given upgrade caller
    /// @param targetPress press contract to check access for
    /// @param upgradeCaller address of upgradeCaller to check access for
    function canUpgrade(
        address targetPress, 
        address upgradeCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if withdraw caller has admin role for given Press
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, upgradeCaller) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            return false;
        }  

        return true;
    }            

    /// @notice checks burun access for a given burn caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param burnCaller address of burnCaller to check access for
    function canBurn(
        address targetPress, 
        uint256 tokenId,
        address burnCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if burnCaller caller has burn access for given target Press
        if (burnCaller != ERC721Press(payable(targetPress)).ownerOf(tokenId)) {
            return false;
        }

        return true;
    }          

    /// @notice checks transfer access for a given transfer caller
    /// @param targetPress press contract to check access for
    /// @param transferCaller address of transferCaller to check access for
    function canTransfer(
        address targetPress, 
        address transferCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if transfer caller has admin role for given Press
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, transferCaller) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            return false;
        }  

        return true;
    }      

    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks value of initialized variable in mintInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {

        // return false if targetPress has not been initialized
        if (configInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }       

    /// @notice checks mint access for a given mintQuantity x mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    function totalMintPrice(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) returns (uint256) {

        // there is no fee (besides gas) to curate a listing
        return 0;
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        address sender = msg.sender;
        
        // data format: initialPause, accessControl, accessControlInit
        (   bool initialPause,
            IAccessControlRegistry accessControl,
            bytes memory accessControlInit
        ) = abi.decode(logicInit, (bool, IAccessControlRegistry, bytes));

        // check if accessControl set to the zero address
        if (address(accessControl) == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // set configInfo[targetPress]
        configInfo[sender].initialized = 1;
        configInfo[sender].isPaused = initialPause;
        // initialize access control
        accessControl.initializeWithData(accessControlInit);

        emit SetAccessControl(sender, accessControl);                   
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| CURATION FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||    

    // function called by mintWithData function in ERC721Press mint call that
    // updates Press specific listings mapping in CuratorStorageV1
    function updateLogicWithData(bytes memory logicData) external {
        // logicData: listings
        (Listing[] memory listings) = abi.decode(logicData, (Listing[]));

        _addListings(msg.sender, listings);

    }

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param targetPress ERC721Press to target 
    /// @param index aka tokenId to retrieve Listing info for 
    function getListing(address targetPress, uint256 index) external view override returns (Listing memory) {
        return idToListing[targetPress][index];
    }

    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListings(address targetPress) external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](configInfo[targetPress].numAdded - configInfo[targetPress].numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < configInfo[targetPress].numAdded; ++i) {
                // skip this listing if curator has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).ownerOf(activeIndex) == address(0)) {
                    continue;
                }

                activeListings[activeIndex] = idToListing[targetPress][i];
                ++activeIndex;
            }
        }
    }

    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListingsForCurator(address targetPress, address curator) external view returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](configInfo[targetPress].numAdded - configInfo[targetPress].numRemoved);

            uint256 activeIndex;

            for (uint256 i; i < configInfo[targetPress].numAdded; ++i) {
                // skip this listing if curator has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).ownerOf(activeIndex) == address(0)) {
                    continue;
                }
                // skip listing if inputted curator address doesnt equal curator for listing
                if (activeListings[i].curator != curator) {
                    continue;
                }

                activeListings[activeIndex] = idToListing[targetPress][i];
                ++activeIndex;
            }
        }
    }    


    /// @dev Allows contract owner to update the ERC721 Curation Pass being used to restrict access to curation functionality
    /// @param targetPress address of Press to target
    /// @param setPaused boolean of new curation active state
    function setCurationPaused(address targetPress, bool setPaused) external {
        // Checks role of msg.sender for access
        if (
            configInfo[targetPress].accessControl.getAccessLevel(targetPress, msg.sender) < ADMIN
            && msg.sender != IERC721Press(targetPress).owner() 
        ) { 
            revert No_Pause_Access();
        }
        // Prevents owner from updating the curation active state to the current active state
        if (configInfo[targetPress].isPaused == setPaused) {
            revert CANNOT_SET_SAME_PAUSED_STATE();
        }

        _setCurationPaused(targetPress, setPaused);
    }

    // internal handler for setCurationPaused function
    function _setCurationPaused(address targetPress, bool _setPaused) internal {
        configInfo[targetPress].isPaused = _setPaused;

        emit CurationPauseUpdated(msg.sender, targetPress, _setPaused);
    }

    /// @dev Allows owner or curator to curate Listings --> which mints a listingRecord token to the msg.sender
    /// @param listings array of Listing structs
    function _addListings(address targetPress, Listing[] memory listings) internal {        
            
        // Access control to prevent non curators/manager/admins from accessing
        if (IAccessControlRegistry(configInfo[targetPress].accessControl).getAccessLevel(address(this), msg.sender) < CURATOR) {
            revert ACCESS_NOT_ALLOWED();
        }            

        _processAddListings(targetPress, listings, msg.sender);
    }

    function _processAddListings(address targetPress, Listing[] memory listings, address sender) internal {
        for (uint256 i = 0; i < listings.length; ++i) {
            if (listings[i].curator != sender) {
                revert WRONG_CURATOR_FOR_LISTING(listings[i].curator, sender);
            }
            if (listings[i].chainId == 0) {
                listings[i].chainId = uint16(block.chainid);
            }
            // increase numAdded by one so that it matches tokenId being minted
            ++configInfo[targetPress].numAdded;
            idToListing[targetPress][configInfo[targetPress].numAdded] = listings[i];            
        }
    }

    /// @dev Allows owner or curator to curate Listings --> which mints listingRecords to the msg.sender
    /// @param targetPress address of target ERC721Press    
    /// @param tokenIds listingRecords to update SortOrders for    
    /// @param sortOrders sortOrdres to update listingRecords
    function updateSortOrders(
        address targetPress, 
        uint256[] calldata tokenIds, 
        int32[] calldata sortOrders
    ) external onlyActive(targetPress) {
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert INVALID_INPUT_LENGTH();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // skip this listing if curator has burned the token (sent to zero address)
            if (ERC721Press(payable(address(targetPress))).ownerOf(tokenIds[i]) != msg.sender) {
                revert No_SortOrder_Access();
            }          
            _setSortOrder(targetPress, tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(targetPress, tokenIds, sortOrders, msg.sender);
    }

    // prevents non-owners from updating the SortOrder on a listingRecord they did not curate themselves 
    function _setSortOrder(address targetPress, uint256 listingId, int32 sortOrder) internal {
        idToListing[targetPress][listingId].sortOrder = sortOrder;
    }

    /// @dev Allows contract owner to freeze all contract functionality starting from a given Unix timestamp
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
            revert CURATION_FROZEN();
        }
        // update frozen at value
        configInfo[targetPress].frozenAt = timestamp;
        emit ScheduledFreeze(targetPress, timestamp);
    }  
}
