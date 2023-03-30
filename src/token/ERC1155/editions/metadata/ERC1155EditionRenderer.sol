// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155PressTokenRenderer} from "../../core/interfaces/IERC1155PressTokenRenderer.sol";
import {IERC1155PressTokenLogic} from "../../core/interfaces/IERC1155PressTokenLogic.sol";
import {IERC1155Press} from "../../core/interfaces/IERC1155Press.sol";

/**
 * @notice ERC1155EditionRenderer
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155EditionRenderer is IERC1155PressTokenRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice supplied value cannot be empty
    error Cannot_SetBlank();
    /// @notice caller does not have permission to edit
    error No_Edit_Access();
    /// @notice address cannot be zero
    error Cannot_SetToZeroAddress();
    /// @notice supplied token does not exist or is yet to be minted
    error Token_DoesntExist();
    /// @notice target Press contract is uninitialized or being accessed by the wrong contract
    error NotInitialized_Or_NotPress();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev MUST emit when the URI is updated for a tokenId as defined in EIP-1155
    /// @param _value string value of URI
    /// @param _id tokenId
    event URI(string _value, uint256 indexed _id);         

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // ERC1155Press => tokenId => uri string
    mapping(address => mapping(uint256 => string)) public tokenUriInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| URI FUNCTIONS ||||||||||||||
    // ||||||||||||||||||||||||||||||||         

    /// @notice uri must be set to non blank string value 
    /// @param tokenId tokenId to init
    /// @param rendererInit data to init with
    function initializeWithData(uint256 tokenId, bytes memory rendererInit) external {
        // data format: uri
        (string memory uriInit) = abi.decode(rendererInit, (string));

        // check if contractURI is being set to empty string
        if (bytes(uriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        // store string URI for given Press for given tokenId
        tokenUriInfo[msg.sender][tokenId] = uriInit;

        // emit URI update event as defined in EIP-1155
        emit URI(uriInit, tokenId);
    }   

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to update
    /// @param tokenId tokenId to target
    /// @param newURI new string URI for token
    function setTokenURI(address targetPress, uint256 tokenId, string memory newURI) external {

        // check if msg.sender has access to update metadata
        if (IERC1155Press(targetPress).getTokenLogic(tokenId).canEditMetadata(targetPress, tokenId, msg.sender) != true) {
            revert No_Edit_Access();
        } 
        
        // check if newURI is being set to empty string
        if (bytes(newURI).length == 0) {
            revert Cannot_SetBlank();
        }

        // update string URI stored for given Press + tokenId
        tokenUriInfo[targetPress][tokenId] = newURI;

        // emit URI update event as defined in EIP-1155
        emit URI(newURI, tokenId);
    }           

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice contract uri for the given Press contract
    /// @dev reverts if a contract uri has not been initialized
    /// @return tokenId uri for the given tokenId of calling contract (if set)
    function uri(uint256 tokenId) 
        external 
        view  
        returns (string memory) 
    {
        string memory tokenURI = tokenUriInfo[msg.sender][tokenId];
        if (bytes(tokenURI).length == 0) {
            /*
            * if uri returns blank, the contract + token has not been initialized
            * or this function is being called by the wrong contract
            */      
            revert NotInitialized_Or_NotPress();
        }
        return tokenURI;
    }

    /// @notice custom getter for contractURI + tokenURI information
    /// @dev reverts if token does not exist
    /// @param targetPress to get contractURI for    
    /// @param tokenId to get tokenURI for
    function uriLookup(address targetPress, uint256 tokenId)
        external
        view
        returns (string memory)
    {
        
        // check if token exists
        if (IERC1155Press(targetPress).tokenCount() < tokenId) {
            revert Token_DoesntExist();
        }         

        // return string uri value for given Press + tokenID
        return tokenUriInfo[targetPress][tokenId];
    }    
}