// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Press} from "../Press.sol";
import {IRenderer} from "../interfaces/IRenderer.sol";
import {IPress} from "../interfaces/IPress.sol";
import {ILogic} from "../interfaces/ILogic.sol";
import {ITokenDecoder} from "../interfaces/ITokenDecoder.sol";
import {BytecodeStorage} from "../utils/BytecodeStorage.sol";

/**
 @notice ArtifactRenderer
 @author Max Bochman
 */
contract ArtifactRenderer is IRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Shared listing struct for both artifactDecoder address + artifactMetadata 
    struct ArtifactDetails {
        address artifactDecoder;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    error Cannot_SetBlank();
    error NO_EDIT_ACCESS();
    error InitializeTokenMetadataFail();
    error Press_NotInitialized();
    error Cannot_SetToZeroAddress();
    error INVALID_INPUT_LENGTH();
    error EditArtifactFail();
    error Token_DoesntExist();
    error NotInitialized_Or_NotPress();
    error Address_NotInitialized();
  

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Press -> contractURI
    mapping(address => string) contractUriInfo;

    /// @notice Press -> tokenId -> {artifactDecoder, artifactMetadata}
    mapping(address => mapping(uint256 => address)) public artifactInfo;      

    // ||||||||||||||||||||||||||||||||
    // ||| CONTRACT URI FUNCTIONS |||||
    // ||||||||||||||||||||||||||||||||         

    /// @notice Default initializer for collection level data of a specific zora ERC721 drop contract
    /// @notice contractURI must be set to non blank string value 
    /// @param rendererInit data to init with
    function initializeWithData(bytes memory rendererInit) external {
        // data format: contractURI
        (string memory contractUriInit) = abi.decode(rendererInit, (string));

        // check if contractURI is being set to empty string
        if (bytes(contractUriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        contractUriInfo[msg.sender] = contractUriInit;
    }   

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to update
    /// @param newContractURI new string contractURI value
    function updateContractURI(address targetPress, string memory newContractURI) external {

        if (ILogic(Press(targetPress).logic()).canEditMetadata(targetPress, msg.sender) != true) {
            revert NO_EDIT_ACCESS();
        } 
        
        // check if contractURI is being set to empty string
        if (bytes(newContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        // update contractURI value
        contractUriInfo[targetPress] = newContractURI;
    }     

    // ||||||||||||||||||||||||||||||||
    // ||| TOKEN METADATA FUNCTIONS |||
    // |||||||||||||||||||||||||||||||| 

    /// @notice sets up metadata schema for each token
    function initializeTokenMetadata(bytes memory artifactMetadataInit) external {
        // data format: artifactDetails[]
        (ArtifactDetails[] memory artifactDetails) = abi.decode(artifactMetadataInit, (ArtifactDetails[]));

        // edit artifactInfo storage for a given Press contract => tokenId
        (bool initSuccess) = _initializeTokenMetadata(msg.sender, artifactDetails);

        // if storage update fails revert transaction
        if (!initSuccess) {
            revert InitializeTokenMetadataFail();
        }                
    }

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to intialize tokens for
    /// @param artifactDetails artifactDetails ArtifactDetails struct array of renderer + init to use for tokens being initd
    function _initializeTokenMetadata(
        address targetPress, 
        ArtifactDetails[] memory artifactDetails
    ) internal returns (bool) {

        // calculate number of artifacts to mint
        uint256 numArtifacts = artifactDetails.length;        

        // call admintMint function on target ZORA contract and store last tokenId minted
        uint256 lastTokenMinted = IPress(targetPress).lastMintedTokenId();        

        // for length of numArtifacts array, emit CreateArtifact event
        for (uint256 i = 0; i < numArtifacts; i++) {  
        
            // get current tokenId to process
            uint256 tokenId = lastTokenMinted - (numArtifacts - (i + 1));                     

            // check if target collection has been initialized
            if (ILogic(Press(targetPress).logic()).isInitialized(targetPress) != true) {
                revert Press_NotInitialized();
            }

            // check if artifactDecoder is zero address
            if (artifactDetails[i].artifactDecoder == address(0)){
                revert Cannot_SetToZeroAddress();
            }

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            address dataContract = BytecodeStorage.writeToBytecode(abi.encode(artifactDetails[i]));

            artifactInfo[targetPress][tokenId] = dataContract;

            // emit ArtifactCreated(
            //     msg.sender,
            //     zoraDrop,
            //     mintRecipient,
            //     tokenId,
            //     dataContract,
            //     artifactDetails[i].artifactDecoder,
            //     artifactDetails[i].artifactMetadata
            // );      
        }    
        return true;
    }                

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to update
    /// @param tokenIds array of tokenIds to target
    /// @param artifactDetails artifactDetails ArtifactDetails struct array of renderer + init to use for tokens being edited
    function updateTokenMetadata(
        address targetPress, 
        uint256[] memory tokenIds,
        ArtifactDetails[] memory artifactDetails
    ) external {

        // check for metadta edit access on given target Press contract
        if (ILogic(Press(targetPress).logic()).canEditMetadata(targetPress, msg.sender) != true) {
            revert NO_EDIT_ACCESS();
        } 
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != artifactDetails.length) {
            revert INVALID_INPUT_LENGTH();
        }

        // edit artifactInfo storage for a given Press contract => tokenId
        (bool editSuccess) = _updateTokenMetadata(targetPress, tokenIds, artifactDetails);

        // if storage update fails revert transaction
        if (!editSuccess) {
            revert EditArtifactFail();
        }        
    }        

    /// @notice function to update contractURI value
    /// @notice contractURI must be set to non blank string value 
    /// @param targetPress address of press to update
    /// @param tokenIds array of tokenIds to target
    /// @param artifactDetails artifactDetails ArtifactDetails struct array of renderer + init to use for tokens being edit
    function _updateTokenMetadata(
        address targetPress, 
        uint256[] memory tokenIds,
        ArtifactDetails[] memory artifactDetails
    ) internal returns (bool) {


        for (uint256 i = 0; i < tokenIds.length; i++) {
        
            // check to see if token exists
            if (IPress(targetPress).lastMintedTokenId() < tokenIds[i]) {
                revert Token_DoesntExist();
            } 

            // check if artifactDecoder is zero address
            if (artifactDetails[i].artifactDecoder == address(0)) {
                revert Cannot_SetToZeroAddress();
            }   

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            // self-destruct data contract currently adssociated with given targetPress => tokenId 
            BytecodeStorage.purgeBytecode(artifactInfo[targetPress][tokenIds[i]]);

            // deploy data contract containing abi.encoded artifactDetails struct
            address dataContract = BytecodeStorage.writeToBytecode(
                abi.encode(artifactDetails[i])
            );

            // map dataContract address to targetPress => tokenId
            artifactInfo[targetPress][tokenIds[i]] = dataContract;

            // // emit ArtifactEdited event
            // emit ArtifactEdited(
            //     msg.sender,
            //     targetPress,
            //     tokenIds[i],
            //     dataContract,
            //     artifactDetails[i].artifactDecoder,
            //     artifactDetails[i].artifactMetadata
            // );   
        }    
        return true;
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice A contract URI for the given drop contract
    /// @dev reverts if a contract uri has not been initialized
    /// @return contract uri for the collection address (if set)
    function contractURI() 
        external 
        view  
        returns (string memory) 
    {
        string memory uri = contractUriInfo[msg.sender];
        if (bytes(uri).length == 0) {
            // if contractURI return is blank, means the contract has not been initialize
            //      or is being called by an address other than press that has been initd
            revert NotInitialized_Or_NotPress();
        }
        return uri;
    }

    /// @notice Token URI information getter
    /// @dev reverts if token does not exist
    /// @param tokenId to get uri for
    /// @return tokenURI uri for given token of collection address (if set)
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {  

        // read + decode artifactDetails stored as bytes in external data contract
        ArtifactDetails memory details = abi.decode(
            BytecodeStorage.readFromBytecode(artifactInfo[msg.sender][tokenId]),
            (ArtifactDetails)
        );

        return ITokenDecoder(details.artifactDecoder).decodeTokenURI(details.artifactMetadata);
    }    

    /// @notice custom getter for contractURI + tokenURI information
    /// @dev reverts if token does not exist
    /// @param targetPress to get contractURI for    
    /// @param tokenId to get tokenURI for
    function artifactDirectory(address targetPress, uint256 tokenId)
        external
        view
        returns (string memory, string memory)
    {
        
        if (ILogic(Press(targetPress).logic()).isInitialized(targetPress) != true) {
            revert Address_NotInitialized();
        }

        if (IPress(targetPress).lastMintedTokenId() < tokenId) {
            revert Token_DoesntExist();
        }         

        // read + decode artifactDetails stored as bytes in external data contract
        ArtifactDetails memory details = abi.decode(
            BytecodeStorage.readFromBytecode(artifactInfo[targetPress][tokenId]),
            (ArtifactDetails)
        );

        // return {string memory contractURI, string memory tokenURI}
        return (contractUriInfo[targetPress], ITokenDecoder(details.artifactDecoder).decodeTokenURI(details.artifactMetadata));
    }    
}