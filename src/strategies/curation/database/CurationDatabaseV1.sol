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

import {ERC721PressDatabaseSkeletonV1} from "../../../core/token/ERC721/database/ERC721PressDatabaseSkeletonV1.sol";
import {ERC721Press} from "../../../core/token/ERC721/ERC721Press.sol";
import {ICurationTypesV1} from "../types/ICurationTypesV1.sol";
import {ICurationLogic} from "../logic/ICurationLogic.sol";
import {DualOwnable} from "../../../core/utils/ownable/dual/DualOwnable.sol";
import {SSTORE2} from "sstore2/SSTORE2.sol";
import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

/**
* @title CurationDatabaseV1
* @notice Curation focused database built for Assembly Press framework
* @dev Inherits from ERC721PressDatabaseSkeletonV1 and implements IERC721PressDatabase required
*       `setOfficiaFactory`, `storeData`, and `overwriteData` functions 
* @dev Introduces custom storage + functions enabling `sortData` functionality
* @author Max Bochman
* @author Salief Lewis
*/
contract CurationDatabaseV1 is ERC721PressDatabaseSkeletonV1, ICurationTypesV1, DualOwnable { 

    ////////////////////////////////////////////////////////////
    // STORAGE
    ////////////////////////////////////////////////////////////        

    // {address targetPress => uint256 tokenId => int128 sortOrder}
    mapping(address => mapping(uint256 => int128)) public slotToSort;   

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////       

    /// @notice Data has been sorted
    event DataSorted(
        address indexed targetPress,
        address indexed sortCaller,
        uint256[] ids,
        int128[] sortOrders
    );   

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////   

    /// @notice msg.sender does not have sort access for given Press
    error No_Sort_Access();      
    /// @notice prevents user from providing invalid inputs
    error Invalid_Input_Length();

    ////////////////////////////////////////////////////////////
    // CONSTRUCTOR 
    ////////////////////////////////////////////////////////////     

    /**
    * @dev Sets primary + secondary contract ownership
    * @param _initialOwner The initial owner address
    * @param _initialSecondaryOwner The initial secondary owner address
    */
    constructor (address _initialOwner, address _initialSecondaryOwner) DualOwnable(_initialOwner, _initialSecondaryOwner) {}    

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    ////////////////////////////////////////////////////////////   

    //////////////////////////////
    // ADMIN 
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

    //////////////////////////////
    // DATA VALIDATION
    ////////////////////////////// 

    /**
    * @dev Internal helper function that checks validity of data to be stored
    *     The function will revert if the data cannot be decoded properly, causing the transaction to fail
    * @param data Data to validate
    */
    function _validateData(bytes memory data) internal view {
        Listing memory listing = abi.decode(data, (Listing));
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
        
        // Calculate number of tokens
        bytes[] memory tokens = abi.decode(data, (bytes[]));

        // Store data for each token
        for (uint256 i = 0; i < tokens.length; ++i) {
            // Check data is valid
            _validateData(tokens[i]);
            // Cache storedCounter
            // NOTE: storedCounter trails associated tokenId by 1
            uint256 storedCounter = settingsInfo[sender].storedCounter;
            // Use sstore2 to store bytes segments from bytes array                
            idToData[sender][storedCounter] = SSTORE2.write(
                tokens[i]
            );       
            emit DataStored(
                sender, 
                storeCaller,
                storedCounter + 1,  
                idToData[sender][storedCounter]
            );                                       
            // increment press storedCounter after storing data
             ++settingsInfo[sender].storedCounter;              
        }       
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
        // Cache msg.sender -- which is the Press if called correctly
        address targetPress = msg.sender;

        // Prevents users from submitting invalid inputs
        if (tokenIds.length != newData.length) {
            revert Invalid_Input_Length();
        }        

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Check data is valid
            _validateData(newData[i]);            
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1] = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }                 

    //////////////////////////////
    // SORT DATA
    //////////////////////////////     

    /**
    * @notice Checks sort access for a given sort caller
    * @param targetPress Press contract to check access for
    * @param sortCaller Address of sortCaller to check access for    
    * @return sortAccess True/false bool
    */
    function canSort(address targetPress, address sortCaller) public view requireInitialized(targetPress) returns (bool sortAccess) {
        return ICurationLogic(settingsInfo[targetPress].logic).getSortAccess(targetPress, sortCaller);            
    }         

    /**
    * @notice Facilitates z-index style sorting of tokenIds.
    * @dev SortOrders can be positive or negative
    * @param targetPress Address of Press to sort tokenIds for
    * @param tokenIds TokenIds to store sortOrders for    
    * @param sortOrders Sort values to store
    */
    function sortData(address targetPress, uint256[] memory tokenIds, int128[] memory sortOrders) external {
        // Cache msg.sender
        address sender = msg.sender;

        // Request sender sort access from database
        if (canSort(targetPress, sender) == false) {
            revert No_Sort_Access();
        }
        // Prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert Invalid_Input_Length();
        }        
        // Store sortOrders for each token
        for (uint256 i; i < tokenIds.length; ++i) {
            slotToSort[targetPress][tokenIds[i]-1] = sortOrders[i];
        }

        emit DataSorted(targetPress, sender, tokenIds, sortOrders);
    }     

    function getAllSortData(address targetPress) external returns (int128[] memory sortOrders) {
        unchecked {
            uint256 returnLength = ERC721Press(payable(targetPress)).totalSupply();

            sortOrders = new int128[](returnLength);     

            for (uint256 i; i < returnLength; ++i) {
                // TODO: potentially add skipping of burning tokens like in readAllData of DB impl?
                sortOrders[i] = slotToSort[targetPress][i];
            }
        }
    }
}

/* Archiving abi.encodePacked version of data storage
* gas was ~ 8k cheaper per token store but there was no way to 
* enforce the type checks in validateData

    //////////////////////////////
    // DATA VALIDATION
    ////////////////////////////// 

    function _validateData(bytes memory data) internal view {
        Listing memory listing = Listing({
            chainId: BytesLib.toUint256(data, 0),
            tokenId: BytesLib.toUint256(data, 32),
            listingAddress: BytesLib.toAddress(data, 64),
            hasTokenId: BytesLib.toUint8(data, 84)                            
        });      
    }     

    //////////////////////////////
    // STORE DATA
    //////////////////////////////    

    function storeData(address storeCaller, bytes calldata data) external requireInitialized(msg.sender) {
        if (data.length == 0) {
            revert Invalid_Input_Length();
        }        
        
        // Cache msg.sender -- which is the Press if called correctly
        address sender = msg.sender;
        
        // Calculate number of tokens
        uint256 tokens = data.length / PACKED_LISTING_STRUCT_LENGTH;

        for (uint256 i = 0; i < tokens; ++i) {
            // Check data is valid
            _validateData(
                data[(i * PACKED_LISTING_STRUCT_LENGTH):((i+1) * PACKED_LISTING_STRUCT_LENGTH)]
            );
            // Cache storedCounter
            // NOTEe: storedCounter trails associated tokenId by 1
            uint256 storedCounter = settingsInfo[sender].storedCounter;
            // Use sstore2 to store bytes segments from bytes array                
            idToData[sender][storedCounter] = SSTORE2.write(
                data[(i * PACKED_LISTING_STRUCT_LENGTH):((i+1) * PACKED_LISTING_STRUCT_LENGTH)]
            );       
            emit DataStored(
                sender, 
                storeCaller,
                storedCounter + 1,  
                idToData[sender][storedCounter]
            );                                       
            // increment press storedCounter after storing data
             ++settingsInfo[sender].storedCounter;              
        }       
    }   

    //////////////////////////////
    // OVERWRITE DATA
    //////////////////////////////                

    function overwriteData(address overwriteCaller, uint256[] memory tokenIds, bytes[] calldata newData) external requireInitialized(msg.sender) {
        // Cache msg.sender
        address targetPress = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Check data is valid
            _validateData(newData[i]);            
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1] = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }  

*/