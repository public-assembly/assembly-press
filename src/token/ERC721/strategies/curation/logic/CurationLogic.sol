// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

import {IERC721PressLogic} from "../../../core/interfaces/IERC721PressLogic.sol";
import {IERC721Press} from "../../../core/interfaces/IERC721Press.sol";
import {ERC721Press} from "../../../ERC721Press.sol";
import {CurationStorageV1} from "../storage/CurationStorageV1.sol";
import {ICurationLogic} from "../interfaces/ICurationLogic.sol";
import {IAccessControl} from "../../../core/interfaces/IAccessControl.sol";

/**
* @title CurationLogic
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
        ) { 
            return false;
        }

        return true;
    }                  

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    /// @dev `mintQuantity` is unused, but present to adhere to the interface requirements of IERC721PressLogic
    function canMint(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) onlyActive(targetPress)  returns (bool) {
        // check if mint caller has minter role for given Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, mintCaller) < CURATOR) { 
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
    /// @dev `tokenId` is unused, but present to adhere to the interface requirements of IERC721PressLogic
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
        // There is no fee (besides gas) to curate a listing
        return configInfo[targetPress].accessControl.getMintPrice(targetPress, mintCaller, mintQuantity);
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
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
    // ||| CURATION FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||     

    // function called by mintWithData function in ERC721Press mint call that
    // updates Press specific listings mapping in CurationStorageV1
    function updateLogicWithData(address updateSender, bytes calldata logicData) external {
        // Access control to prevent non curators/manager/admins from accessing
        if (configInfo[msg.sender].accessControl.getAccessLevel(msg.sender, updateSender) < CURATOR) {
            revert ACCESS_NOT_ALLOWED();
        }              
        
        if (logicData.length % LISTING_SIZE != 0) {
            revert INVALID_INPUT_DATA();
        }

        // calculate number of listings
        uint256 numListings = logicData.length / LISTING_SIZE;

        for (uint256 i; i < numListings; ++i) {
            uint256 sliceStart = i * LISTING_SIZE;
            _addListing(msg.sender, logicData[sliceStart: sliceStart + LISTING_SIZE]);
        }
    }        

    /// @dev Allows owner or curator to curate Listings --> which mints a listingRecord token to the msg.sender
    /// @param listing Listing struct encoded bytes
    function _addListing(address targetPress, bytes calldata listing) internal {                          
        idToListing[targetPress][configInfo[targetPress].numAdded] = listing;    
        ++configInfo[targetPress].numAdded;            
    }       

    function _bytesToListing(bytes memory data) internal view returns (Listing memory) {

        (
            uint128 chainId, 
            uint128 tokenId, 
            address listingAddress, 
            int32 sortOrder, 
            bool hasTokenId
        ) = abi.decode(data, (uint128, uint128, address, int32, bool));

        Listing memory listing = Listing({
            chainId: chainId,
            tokenId: tokenId,
            listingAddress: listingAddress,
            sortOrder: sortOrder,
            hasTokenId: hasTokenId
        });

        return listing;
    }

    function _listingToBytes(Listing memory inputListing) internal pure returns (bytes memory) {
        return abi.encode(
            inputListing.chainId,
            inputListing.tokenId,
            inputListing.listingAddress,
            inputListing.hasTokenId,
            inputListing.sortOrder
        );   
    }

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve Listing info for 
    function getListing(address targetPress, uint256 tokenId) external view override returns (Listing memory) {
        return _bytesToListing(idToListing[targetPress][tokenId-1]);
    }

    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListings(address targetPress) external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](configInfo[targetPress].numAdded - configInfo[targetPress].numRemoved);

            // first tokenId minted in ERC721Press impl is #1
            uint256 activeIndex = 1;

            for (uint256 i; i < configInfo[targetPress].numAdded; ++i) {
                // skip this listing if curator has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).exists(activeIndex) != true) {
                    continue;
                }
                activeListings[activeIndex-1] = _bytesToListing(idToListing[targetPress][i]);
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

    /// @dev Allows owner or curator to curate Listings --> which mints listingRecords to the msg.sender
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
            revert INVALID_INPUT_LENGTH();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // prevents non-owners from updating the SortOrder on a listingRecord they did not curate themselves 
            if (ERC721Press(payable(address(targetPress))).ownerOf(tokenIds[i]) != msg.sender) {
                revert No_SortOrder_Access();
            }          
            _setSortOrder(targetPress, tokenIds[i], sortOrders[i]);
        }
        emit UpdatedSortOrder(targetPress, tokenIds, sortOrders, msg.sender);
    }

    // prevents non-owners from updating the SortOrder on a listingRecord they did not curate themselves 
    function _setSortOrder(address targetPress, uint256 listingId, int32 sortOrder) internal {
        
        // convert listing bytes to listing struct and cache
        Listing memory tempListing = _bytesToListing(idToListing[targetPress][listingId]);

        // update sort order value of listing
        tempListing.sortOrder = sortOrder;

        // re encode listing struct to bytes and store
        idToListing[targetPress][listingId] = _listingToBytes(tempListing);
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
            revert CURATION_FROZEN();
        }
        // update frozen at value
        configInfo[targetPress].frozenAt = timestamp;
        emit ScheduledFreeze(targetPress, timestamp);
    }  
}