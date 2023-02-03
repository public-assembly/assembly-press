// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721PressRenderer} from "../../interfaces/IERC721PressRenderer.sol";
import {IERC721Press} from "../../interfaces/IERC721Press.sol";
import {IERC721PressLogic} from "../../interfaces/IERC721PressLogic.sol";
import {ITokenDecoder} from "../../interfaces/ITokenDecoder.sol";
import {ERC721Press} from "../../ERC721Press.sol";
import {BytecodeStorage} from "../../../../utils/utils/BytecodeStorage.sol";

/**
 @notice ArtifactRenderer
 @author Max Bochman
 @author Salief Lewis
 */
contract ArtifactRenderer is IERC721PressRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Shared struct for both artifactDecoder address + artifactMetadata 
    struct ArtifactDetails {
        address artifactDecoder;
        bytes artifactMetadata;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice supplied value cannot be empty
    error Cannot_SetBlank();
    /// @notice caller does not have permission to edit
    error No_Edit_Access();
    /// @notice unsuccessful attempt to update metadata
    error InitializeTokenMetadataFail();
    /// @notice target Press contract is uninitialized
    error Press_NotInitialized();
    /// @notice address cannot be zero
    error Cannot_SetToZeroAddress();
    /// @notice unsuccessful attempt to edit an existing artifact
    error EditArtifactFail();
    /// @notice supplied token does not exist or is yet to be minted
    error Token_DoesntExist();
    /// @notice target Press contract is uninitialized or being accessed by the wrong Press
    error NotInitialized_Or_WrongPress();
    /// @notice prevents users from submitting invalid inputs to the grant role function
    error Invalid_Input_Length();

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Press -> contractURI
    mapping(address => string) contractUriInfo;

    /// @notice Press -> tokenId -> {artifactDecoder, artifactMetadata}
    mapping(address => mapping(uint256 => address)) public artifactInfo;    
    
    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Event triggered when contractURI is updated
    /// @param sender address that sent update txn
    /// @param press address of Press to update contractURI for
    /// @param contractURI new contractURI
    event UpdatedContractURI(
        address indexed sender,
        address indexed press,
        string contractURI
    );     

    /// @notice Event triggered when an artifact is created
    /// @param press address of Press to create artifact from
    /// @param tokenId tokenId of created artifact
    /// @param dataContract address of resulting dataContract
    event ArtifactCreated(
        address indexed press,
        uint256 indexed tokenId,
        address dataContract
    );        

    /// @notice Event triggered when an artifact is edited
    /// @param press address of Press to create artifact from
    /// @param tokenId tokenId of created artifact
    /// @param dataContract address of resulting dataContract
    event ArtifactEdited(
        address indexed press,
        uint256 indexed tokenId,
        address dataContract
    );           

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

        if (ERC721Press(payable(targetPress)).getLogic().canEditMetadata(targetPress, msg.sender) != true) {
            revert No_Edit_Access();
        } 
        
        // check if contractURI is being set to empty string
        if (bytes(newContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        // update contractURI value
        contractUriInfo[targetPress] = newContractURI;

        emit UpdatedContractURI({ 
            sender: msg.sender,
            press: targetPress,
            contractURI: newContractURI
        });
    }     

    // ||||||||||||||||||||||||||||||||
    // ||| TOKEN METADATA FUNCTIONS |||
    // |||||||||||||||||||||||||||||||| 

    /// @notice sets up metadata schema for each token
    function initializeTokenMetadata(bytes memory tokenInit) external {

        // check if target Press has been initialized
        if (ERC721Press(payable(msg.sender)).getLogic().isInitialized(msg.sender) != true) {
            revert Press_NotInitialized();
        }

        // data format: artifactDetails[]
        (ArtifactDetails[] memory artifactDetails) = abi.decode(tokenInit, (ArtifactDetails[]));

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

        // calculate number of artifacts to initialize
        uint256 numArtifacts = artifactDetails.length;        

        // cache lastMintedtokenId from target Press
        uint256 lastTokenMinted = IERC721Press(targetPress).lastMintedTokenId();        

        // for length of numArtifacts array, emit ArtifactCreated event
        for (uint256 i = 0; i < numArtifacts; i++) {  
        
            // cache current tokenId to process
            uint256 tokenId = lastTokenMinted - (numArtifacts - (i + 1));                     

            // check if artifactDecoder is zero address
            if (artifactDetails[i].artifactDecoder == address(0)){
                revert Cannot_SetToZeroAddress();
            }

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            // cache dataContract address after deploying + storing encoded artifactDetails as raw bytecode
            address dataContract = BytecodeStorage.writeToBytecode(abi.encode(artifactDetails[i]));

            // set dataContract address to given targetPress => tokenId
            artifactInfo[targetPress][tokenId] = dataContract;

            emit ArtifactCreated(
                targetPress,
                tokenId,
                dataContract
            );      
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
        if (ERC721Press(payable(targetPress)).getLogic().canEditMetadata(targetPress, msg.sender) != true) {
            revert No_Edit_Access();
        } 
        
        // prevents users from submitting invalid inputs
        if (tokenIds.length != artifactDetails.length) {
            revert Invalid_Input_Length();
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
            if (IERC721Press(targetPress).lastMintedTokenId() < tokenIds[i]) {
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

            // map dataContract address to targetPress => tokenId
            artifactInfo[targetPress][tokenIds[i]] = BytecodeStorage.writeToBytecode(
                abi.encode(artifactDetails[i])
            );

            emit ArtifactEdited(
                targetPress,
                tokenIds[i],
                artifactInfo[targetPress][tokenIds[i]]
            );                   
        } 

        return true;
    }            

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice contract uri for the given Press contract
    /// @dev reverts if a contract uri has not been initialized
    /// @return contract uri for the collection address (if set)
    function contractURI() 
        external 
        view  
        returns (string memory) 
    {
        string memory uri = contractUriInfo[msg.sender];
        if (bytes(uri).length == 0) {
            /*
            * if contractURI returns blank, the contract has not been initialized
            * or this function is being called by another Press contract
            */      
            revert NotInitialized_Or_WrongPress();
        }
        return uri;
    }

    /// @notice token uri getter
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
    function artifactLookup(address targetPress, uint256 tokenId)
        external
        view
        returns (string memory, string memory)
    {
        
        if (ERC721Press(payable(targetPress)).getLogic().isInitialized(targetPress) != true) {
            revert Press_NotInitialized();
        }

        if (IERC721Press(targetPress).lastMintedTokenId() < tokenId) {
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