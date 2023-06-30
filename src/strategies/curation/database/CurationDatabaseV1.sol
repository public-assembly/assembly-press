// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {ERC721PressDatabaseSkeletonV1} from "../../../core/token/ERC721/database/ERC721PressDatabaseSkeletonV1.sol";
import {DualOwnable} from "../../../core/utils/ownable/dual/DualOwnable.sol";
import "sstore2/SSTORE2.sol";

/**
* @title CurationDatabaseV1
* @notice Curation focused database built on Assembly Press framework
* @dev Inherits ERC721PressDatabaseV1
*
* @author Max Bochman
* @author Salief Lewis
*/
contract CurationDatabaseV1 is ERC721PressDatabaseSkeletonV1, DualOwnable { 

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||       

    /// @dev Sets primary + secondary contract ownership
    /// @param _initialOwner The initial owner address
    /// @param _initialSecondaryOwner The initial secondary owner address
    constructor (address _initialOwner, address _initialSecondaryOwner) DualOwnable(_initialOwner, _initialSecondaryOwner) {}    

    // ||||||||||||||||||||||||||||||||
    // ||| DATABASE ADMIN |||||||||||||
    // ||||||||||||||||||||||||||||||||     

    function setOfficialFactory(address factory) eitherOwner external {
        _officialFactories[factory] = true;
        emit NewFactoryAdded(msg.sender, factory);
    }

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

    /// @dev Internal helper function that checks if the data being stored is valid.
    ///     The function will revert if the data cannot be decoded properly, causing the transaction to fail
    /// @param data Data to check
    function _checkValid(bytes memory data) internal pure {
        Listing memory listing = abi.decode(data, (Listing));
    }       

    function _storeData(address targetPress, address storeCaller, bytes[] memory tokens) internal {   
        for (uint256 i = 0; i < tokens.length; ++i) {
            // Check data is valid
            _checkValid(tokens[i]);
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

    /// @dev Updates sstore2 data pointers for already existing tokens
    /// @param overwriteCaller address of account initiating `update()` from targetPress
    /// @param tokenIds arbitrary encoded bytes data
    /// @param newData data passed in alongside update call
    function overwriteData(address overwriteCaller, uint256[] memory tokenIds, bytes[] calldata newData) external requireInitialized(msg.sender) {
        // Cache msg.sender
        address targetPress = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Check data is valid
            _checkValid(newData[i]);            
            // use sstore2 to store bytes segments in bytes array
            address newPointer = idToData[targetPress][tokenIds[i]-1].pointer = SSTORE2.write(
                newData[i]
            );                                
            emit DataOverwritten(targetPress, overwriteCaller, tokenIds[i], newPointer);                                
        }                  
    }                     
}