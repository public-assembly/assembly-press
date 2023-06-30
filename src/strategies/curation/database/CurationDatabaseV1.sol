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
import {DualOwnable} from "../../../core/utils/ownable/dual/DualOwnable.sol";
import "sstore2/SSTORE2.sol";

/**
* @title CurationDatabaseV1
* @notice Curation focused database built on Assembly Press framework
* @dev Inherits from ERC721PressDatabaseSkeletonV1 and implements custom `setOfficiaFactory`,
*       `storeData`, and `overwriteData` functions without introducing any non-standard storage or events
* @author Max Bochman
* @author Salief Lewis
*/
contract CurationDatabaseV1 is ERC721PressDatabaseSkeletonV1, DualOwnable { 

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
    // CONSTRUCTOR 
    ////////////////////////////////////////////////////////////     

    /**
    * @dev Sets primary + secondary contract ownership
    * @param _initialOwner The initial owner address
    * @param _initialSecondaryOwner The initial secondary owner address
    */
    constructor (address _initialOwner, address _initialSecondaryOwner) DualOwnable(_initialOwner, _initialSecondaryOwner) {}    

    ////////////////////////////////////////////////////////////
    // DATABASE ADMIN 
    ////////////////////////////////////////////////////////////   

    /**
    * @notice Gives factory ability to initalize contracts in this database
    * @dev Ability cannot be removed once set
    * @param factory Address of factory to grant initialise ability
    */
    function setOfficialFactory(address factory) eitherOwner external {
        _officialFactories[factory] = true;
        emit NewFactoryAdded(msg.sender, factory);
    }

    ////////////////////////////////////////////////////////////
    // CUSTOM DATA VALIDATION + STORE + OVERWRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
    * @dev Internal helper function that checks validity of data to be stored
    *     The function will revert if the data cannot be decoded properly, causing the transaction to fail
    * @param data Data to check
    */
    function _validateData(bytes memory data) internal pure {
        Listing memory listing = abi.decode(data, (Listing));
    }       

    /**
    * @dev Function called by mintWithData function in ERC721Press mint call that
    *      updates specific tokenData for msg.sender, so no need to add access control to this function
    * @param storeCaller address of account initiating `mintWithData()` from targetPress
    * @param data data getting passed in along mint
    */
    function storeData(address storeCaller, bytes calldata data) external requireInitialized(msg.sender) {
        // Cache msg.sender -- which is the Press if called correctly
        address sender = msg.sender;
        
        // data format: tokens
        (bytes[] memory tokens) = abi.decode(data, (bytes[]));

        for (uint256 i = 0; i < tokens.length; ++i) {
            // Check data is valid
            _validateData(tokens[i]);
            // cache storedCounter
            uint256 storedCounter = settingsInfo[sender].storedCounter;
            // use sstore2 to store bytes segments in bytes array
            idToData[sender][storedCounter].pointer = SSTORE2.write(
                tokens[i]
            );       
            // NOTE: storedCounter trails the tokenId being minted by 1
            emit DataStored(
                sender, 
                storeCaller,
                storedCounter,  
                idToData[sender][storedCounter].pointer
            );                                       
            // increment press storedCounter after storing data
            ++settingsInfo[sender].storedCounter;              
        }        
    }              

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
            // Check data is valid
            _validateData(newData[i]);            
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1].pointer = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }                     
}