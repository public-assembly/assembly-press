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

import {IERC721PressLogic} from "../../core/interfaces/IERC721PressLogic.sol";
import {IERC721Press} from "../../core/interfaces/IERC721Press.sol";
import {ERC721Press} from "../../ERC721Press.sol";
import {CurationStorageV1} from "../storage/CurationStorageV1.sol";
import {ICurationLogic} from "../interfaces/ICurationLogic.sol";
import {IAccessControlRegistry} from "../../../../../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

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

    /// @notice checks upgrade access for a given upgrade caller
    /// @param targetPress press contract to check access for
    /// @param upgradeCaller address of upgradeCaller to check access for
    function canUpgrade(
        address targetPress, 
        address upgradeCaller
    ) external view requireInitialized(targetPress) returns (bool) {
        // check if withdraw caller has admin role for given Press
        if (configInfo[targetPress].accessControl.getAccessLevel(targetPress, upgradeCaller) < ADMIN) { 
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
        if (
            burnCaller != ERC721Press(payable(targetPress)).ownerOf(tokenId)
            && configInfo[targetPress].accessControl.getAccessLevel(targetPress, burnCaller) < ADMIN
        ) {
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

    /// @notice checks mint access for a given mintQuantity x mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
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
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        address sender = msg.sender;
        // data format: initialPause, accessControl, accessControlInit
        (   
            bool initialPause,
            IAccessControlRegistry accessControl,
            bytes memory accessControlInit
        ) = abi.decode(logicInit, (bool, IAccessControlRegistry, bytes));

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
    function updateLogicWithData(address updateSender, bytes memory logicData) external {
        // Access control to prevent non curators/manager/admins from accessing
        if (configInfo[msg.sender].accessControl.getAccessLevel(msg.sender, updateSender) < CURATOR) {
            revert ACCESS_NOT_ALLOWED();
        }              

        // logicData: listings
        (Listing[] memory listings) = abi.decode(logicData, (Listing[]));
        
        // msg.sender must be the ERC721Press contract in this instance. 
        // even if someone wanted to put in a fake updateSender address by calling this through etherscan
        // they wouldnt be able to spoof the fact that msg.sender on this is the ERC721Press
        // _addListings(msg.sender, updateSender, decodeListings(logicData));
        _addListings(msg.sender, updateSender, listings);
    }

    // /**
    // * @notice Decodes packed listings data into Listing structs
    // * @dev Assumes that the input data is correctly packed, and will produce undefined behavior if it is not.
    // * @param data Packed listing data
    // * @return listings Array of decoded Listing structs
    // */
    // function decodeListings(bytes memory data) internal pure returns (ICurationLogic.Listing[] memory) {
    //     // Calculate the number of listings by dividing the total length of data by the size of a single listing
    //     uint256 numListings = data.length / LISTING_SIZE;

    //     // Create a new memory array of listings with the calculated length
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](numListings);

    //     // Define variables that will be used in the assembly block
    //     uint256 srcPtr;
    //     uint256 dstPtr;

    //     // Assembly block for decoding the packed data
    //     assembly {
    //         // Get the memory address of the data input
    //         srcPtr := add(data, 0x20)

    //         // Get the memory address of the listings array
    //         dstPtr := add(listings, 0x20)
    //     }

    //     // Iterate through the listings and decode each one
    //     for (uint256 i = 0; i < numListings; i++) {
    //         // Decode each field of the listing struct from the packed data

    //         // 1. curatedAddress (20 bytes)
    //         // Load data from the source pointer, shift right by 96 bits to align the address,
    //         // and store the result in the curatedAddress variable.
    //         address curatedAddress;
    //         assembly {
    //             curatedAddress := shr(96, mload(srcPtr))
    //             srcPtr := add(srcPtr, 20)
    //         }

    //         // 2. selectedTokenId (12 bytes)
    //         // Load data from the source pointer, shift right by 224 bits to align the uint96,
    //         // and store the result in the selectedTokenId variable.
    //         uint96 selectedTokenId;
    //         assembly {
    //             selectedTokenId := shr(224, mload(srcPtr))
    //             srcPtr := add(srcPtr, 12)
    //         }

    //         // 3. curator (20 bytes)
    //         // Load data from the source pointer, shift right by 96 bits to align the address,
    //         // and store the result in the curator variable.
    //         address curator;
    //         assembly {
    //             curator := shr(128, mload(srcPtr))
    //             srcPtr := add(srcPtr, 20)
    //         }

    //         // 4. sortOrder (4 bytes)
    //         // Load data from the source pointer, shift right by 224 bits to align the int32,
    //         // and store the result in the sortOrder variable.
    //         int32 sortOrder;
    //         assembly {
    //             sortOrder := shr(224, mload(srcPtr))
    //             srcPtr := add(srcPtr, 4)
    //         }

    //         // 5. chainId (2 bytes)
    //         // Load data from the source pointer, shift right by 240 bits to align the uint16,
    //         // and store the result in the chainId variable.
    //         uint16 chainId;
    //         assembly {
    //             chainId := shr(240, mload(srcPtr))
    //             srcPtr := add(srcPtr, 2)
    //         }

    //         // 6. curationTargetType (2 bytes)
    //         // Load data from the source pointer, shift right by 240 bits to align the uint16,
    //         // and store the result in the curationTargetType variable.
    //         uint16 curationTargetType;
    //         assembly {
    //             curationTargetType := shr(240, mload(srcPtr))
    //             srcPtr := add(srcPtr, 2)
    //         }     

    //         // 7. hasTokenId (1 byte)
    //         // Load data from the source pointer, extract the least significant byte,
    //         // compare it with 1, and store the result in the hasTokenId variable.
    //         bool hasTokenId;
    //         assembly {
    //             hasTokenId := eq(byte(0, mload(srcPtr)), byte(0, 1))
    //             srcPtr := add(srcPtr, 1)
    //         }

    //         // Populate the listing struct with the decoded fields
    //         // Assign the decoded values to the corresponding fields of the Listing struct
    //         // and store it in the listings array at index i.
    //         listings[i] = ICurationLogic.Listing({
    //             curatedAddress: curatedAddress,
    //             selectedTokenId: selectedTokenId,
    //             curator: curator,
    //             sortOrder: sortOrder,
    //             chainId: chainId,
    //             curationTargetType: curationTargetType,
    //             hasTokenId: hasTokenId
    //         });        
    //     }

    //     // Return the decoded listings array
    //     return listings;
    // }        

    // /**
    // * @notice Decodes packed listings data into Listing structs
    // * @dev Assumes that the input data is correctly packed, and will produce undefined behavior if it is not.
    // * @param data Packed listing data
    // * @return listings Array of decoded Listing structs
    // */
    // function decodeListings(bytes memory data) internal pure returns (ICurationLogic.Listing[] memory) {
    //     // Calculate the number of listings by dividing the total length of data by the size of a single listing
    //     uint256 numListings = data.length / LISTING_SIZE;

    //     // Create a new memory array of listings with the calculated length
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](numListings);

    //     // Define the source pointer variable
    //     uint256 srcPtr;

    //     // Assembly block for initializing the source pointer
    //     assembly {
    //         // Get the memory address of the data input
    //         srcPtr := add(data, 0x20)
    //     }

    //     // Iterate through the listings and decode each one
    //     for (uint256 i = 0; i < numListings; i++) {
    //         // Assembly block for decoding the packed data and populating the Listing struct
    //         assembly {
    //             // 1. curatedAddress (20 bytes)
    //             let curatedAddress := shr(96, mload(srcPtr))
    //             srcPtr := add(srcPtr, 20)

    //             // 2. selectedTokenId (12 bytes)
    //             let selectedTokenId := shr(224, mload(srcPtr))
    //             srcPtr := add(srcPtr, 12)

    //             // 3. curator (20 bytes)
    //             let curator := shr(96, mload(srcPtr))
    //             srcPtr := add(srcPtr, 20)

    //             // 4. sortOrder (4 bytes)
    //             let sortOrder := shr(224, mload(srcPtr))
    //             srcPtr := add(srcPtr, 4)

    //             // 5. chainId (2 bytes)
    //             let chainId := shr(240, mload(srcPtr))
    //             srcPtr := add(srcPtr, 2)

    //             // 6. curationTargetType (2 bytes)
    //             let curationTargetType := shr(240, mload(srcPtr))
    //             srcPtr := add(srcPtr, 2)

    //             // 7. hasTokenId (1 byte)
    //             let hasTokenId := eq(byte(0, mload(srcPtr)), byte(0, 1))
    //             srcPtr := add(srcPtr, 1)

    //             // Get the memory address of the listings array at index i
    //             let dstPtr := add(add(listings, mul(i, 64)), 0x20)

    //             // Store the decoded fields in the Listing struct at the destination pointer
    //             mstore(dstPtr, curatedAddress)
    //             mstore(add(dstPtr, 20), selectedTokenId)
    //             mstore(add(dstPtr, 32), curator)
    //             mstore(add(dstPtr, 52), sortOrder)
    //             mstore(add(dstPtr, 56), chainId)
    //             mstore(add(dstPtr, 58), curationTargetType)
    //             mstore(add(dstPtr, 60), hasTokenId)
    //         }
    //     }

    //     // Return the decoded listings array
    //     return listings;
    // }
    

    /// @dev Getter for acessing Listing information for a specific tokenId
    /// @param targetPress ERC721Press to target 
    /// @param tokenId tokenId to retrieve Listing info for 
    function getListing(address targetPress, uint256 tokenId) external view override returns (Listing memory) {
        return idToListing[targetPress][tokenId-1];
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

                activeListings[activeIndex-1] = idToListing[targetPress][i];
                ++activeIndex;
            }
        }
    }

    /// @dev Getter for acessing Listing information for all active listings
    /// @param targetPress ERC721Press to target     
    function getListingsForCurator(address targetPress, address curator) external view override returns (Listing[] memory activeListings) {
        unchecked {
            activeListings = new Listing[](configInfo[targetPress].numAdded - configInfo[targetPress].numRemoved);

            // first tokenId in ERC721Press impl is #1
            uint256 activeIndex = 1;

            for (uint256 i; i < configInfo[targetPress].numAdded; ++i) {
                // skip this listing if curator has burned the token (sent to zero address)
                if (ERC721Press(payable(targetPress)).ownerOf(activeIndex) == address(0)) {
                    continue;
                }
                // skip listing if inputted curator address doesnt equal curator for listing
                if (idToListing[targetPress][i].curator != curator) {       
                    continue;
                }

                activeListings[activeIndex-1] = idToListing[targetPress][i];
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
    function _addListings(address targetPress, address curator, Listing[] memory listings) internal {                          

        for (uint256 i = 0; i < listings.length; ++i) {
            if (listings[i].curator != curator) {
                revert WRONG_CURATOR_FOR_LISTING(listings[i].curator, curator);
            }
            if (listings[i].chainId == 0) {
                listings[i].chainId = uint16(block.chainid);
            }
            idToListing[targetPress][configInfo[targetPress].numAdded] = listings[i];                    
            ++configInfo[targetPress].numAdded;            
        }
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
        idToListing[targetPress][listingId].sortOrder = sortOrder;
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
