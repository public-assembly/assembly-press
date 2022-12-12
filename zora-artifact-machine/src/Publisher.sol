// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {IERC721DropMinter} from "./interfaces/IERC721DropMinter.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";
import {IPublisher} from "./interfaces/IPublisher.sol";
import {IDefaultMetadataDecoder} from "./interfaces/IDefaultMetadataDecoder.sol";
import {PublisherStorage} from "./PublisherStorage.sol";

/** 
 * @title Publisher.sol
 * @dev Minting module & registry that initializes unique token rendering strategy + metadata upon collection init + each mint 
 *      for specific token Ids of a given zora ERC721Drop collection
 * @dev Can be used by any zora ERC721Drop collection
 * @author Max Bochman
 */
contract Publisher is 
    IMetadataRenderer, 
    IPublisher,
    PublisherStorage,
    Ownable, 
    ReentrancyGuard 
{
    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZATION FUNCTION ||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Default initializer for collection level data of a specific zora ERC721 drop contract
    /// @notice contractURI must be set to non blank string value 
    /// @param data data to init with
    function initializeWithData(bytes memory data) external {
        // data format: contractURI, mintPricePerToken, accessControlModule, accessControlInit
        (
            string memory contractUriInit, 
            uint256 mintPriceInit,
            address accessControlModule, 
            bytes memory accessControlInit
        ) = abi.decode(data, (string, uint256, address, bytes));

        // check if contractURI is being set to empty string
        if (bytes(contractUriInit).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[msg.sender] = contractUriInit;

        mintPricePerToken[msg.sender] = mintPriceInit;

        emit MintPriceUpdated(msg.sender, msg.sender, mintPriceInit);        

        IAccessControlRegistry(accessControlModule).initializeWithData(accessControlInit);

        dropAccessControl[msg.sender] = accessControlModule;    
        
        emit PublicationInitialized({
            target: msg.sender,
            contractURI: contractUriInit,
            mintPricePerToken: mintPriceInit,
            accessControl: accessControlModule,
            accessControlInit: accessControlInit
        });
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL MINTING FUNCTION ||
    // |||||||||||||||||||||||||||||||| 

    /// @notice allows you to mint a token with arbitrary metadata + arbitrary metadata structure
    /// @dev calls adminMint function in ZORA Drop contract + initializes artifactDetails
    /// @param zoraDrop ZORA Drop contract to mint from
    /// @param mintRecipient address to recieve minted tokens
    /// @param artifactDetails ArtifactDetails struct array of renderer + init to use for token being minted 
    function publish(
        address zoraDrop,
        address mintRecipient,
        ArtifactDetails[] memory artifactDetails
    ) external payable nonReentrant {

        // check if Publisher.sol contract has MINTER_ROLE on target ZORA Drop contract
        if (
            !IERC721DropMinter(zoraDrop).hasRole(
                MINTER_ROLE,
                address(this)
        )) {
            revert MinterNotAuthorized();
        }

        // check if msg.sender has publication access
        if (IAccessControlRegistry(dropAccessControl[zoraDrop]).getAccessLevel(address(this), msg.sender) < 1) {
            revert No_PublicationAccess();
        }        

        // check if total mint price is correct
        if (msg.value != mintPricePerToken[zoraDrop] * artifactDetails.length) {            
            revert WrongPrice();
        }

        // set artifactInfo storage for a given ZORA ERC721Drop contract => tokenId
        (bool artifactSuccess) = _publish(zoraDrop, mintRecipient, artifactDetails);

        // if storage update fails revert transaction
        if (!artifactSuccess) {
            revert CreateArtifactFail();
        }

        // Transfer funds to zora drop contract
        (bool bundleSuccess, ) = zoraDrop.call{value: msg.value}("");

        // if msg.value transfer fails revert transaction
        if (!bundleSuccess) {
            revert TransferNotSuccessful();
        }
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL MINTING FUNCTION ||
    // ||||||||||||||||||||||||||||||||

    function _publish(
        address zoraDrop,
        address mintRecipient,
        ArtifactDetails[] memory artifactDetails      
    ) internal returns (bool) {

        // calculate number of artifacts to mint
        uint256 numArtifacts = artifactDetails.length;        

        // call admintMint function on target ZORA contract and store last tokenId minted
        uint256 lastTokenMinted = IERC721DropMinter(zoraDrop).adminMint(mintRecipient, numArtifacts);        

        // for length of numArtifacts array, emit CreateArtifact event
        for (uint256 i = 0; i < numArtifacts; i++) {            

            // get current tokenId to process
            uint256 tokenId = lastTokenMinted - (numArtifacts - (i + 1));                     

            // check if target collection has been initialized
            if (bytes(contractURIInfo[zoraDrop]).length == 0) {
                revert Address_NotInitialized();
            }        

            // check if artifactRenderer is zero address
            if (artifactDetails[i].artifactRenderer == address(0)){
                revert Cannot_SetToZeroAddress();
            }

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }        

            artifactInfo[zoraDrop][tokenId] = artifactDetails[i];

            emit ArtifactCreated(
                msg.sender,
                zoraDrop,
                mintRecipient,
                tokenId,
                artifactDetails[i].artifactRenderer,
                artifactDetails[i].artifactMetadata
            );                 
        }
        return true;
    }           

    // ||||||||||||||||||||||||||||||||
    // ||| EXTNERAL EDIT FUNCTIONS ||||
    // ||||||||||||||||||||||||||||||||   

    /// @notice function that enables editing artifactDetails for a given tokenId
    /// @param zoraDrop collection address to target
    /// @param tokenIds uint256 tokenIds to target
    /// @param artifactDetails ArtifactDetails struct array of renderer + init to use for token being minted 
    function edit(
        address zoraDrop, 
        uint256[] memory tokenIds, 
        ArtifactDetails[] memory artifactDetails 
    )   external {

        // prevents users from submitting invalid inputs
        if (tokenIds.length != artifactDetails.length) {
            revert INVALID_INPUT_LENGTH();
        }

        // check if msg.sender has access to update metadata for a token
        if (IAccessControlRegistry(dropAccessControl[zoraDrop]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }          

        // edit artifactInfo storage for a given ZORA ERC721Drop contract => tokenId
        (bool editSuccess) = _edit(zoraDrop, tokenIds, artifactDetails);

        // if storage update fails revert transaction
        if (!editSuccess) {
            revert EditArtifactFail();
        }
    }           

    /// @notice function to update contractURI
    /// @param newContractURI new contractURI
    function updateContractURI(address target, string memory newContractURI)
        external
    {
        // check if msg.sender has access to update access for a collection
        if (IAccessControlRegistry(dropAccessControl[target]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }

        // check if contract has been initialized + if 
        if (bytes(contractURIInfo[target]).length == 0) {
            revert Address_NotInitialized();
        }

        // check if contractURI is being set to empty string
        if (bytes(newContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[target] = newContractURI;

        emit ContractURIUpdated({
            target: target,
            sender: msg.sender,
            contractURI: newContractURI
        });
    }      

    /// @dev updates uint256 value in mintPricePerToken mapping
    /// @param newMintPricePerToken new mintPrice value
    function updateMintPrice(address target, uint256 newMintPricePerToken) public {

        // check if msg.sender has access to edit access for a collection
        if (IAccessControlRegistry(dropAccessControl[target]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_EditAccess();
        }

        mintPricePerToken[target] = newMintPricePerToken;

        emit MintPriceUpdated(msg.sender, target, newMintPricePerToken);
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL EDIT FUNCTIONS ||||
    // ||||||||||||||||||||||||||||||||   

    function _edit(
        address zoraDrop, 
        uint256[] memory tokenIds, 
        ArtifactDetails[] memory artifactDetails
    ) internal returns (bool) {

        for (uint256 i = 0; i < tokenIds.length; i++) {
        
            // check to see if token exists
            if (ERC721Drop(payable(zoraDrop)).saleDetails().totalMinted < tokenIds[i]) {
                revert Token_DoesntExist();
            } 

            // check if tokenRenderer is zero address
            if (artifactDetails[i].artifactRenderer == address(0)) {
                revert Cannot_SetToZeroAddress();
            }   

            // check if artifactMetadata is empty
            if (artifactDetails[i].artifactMetadata.length == 0) {
                revert Cannot_SetBlank();
            }         

            artifactInfo[zoraDrop][tokenIds[i]] = artifactDetails[i]; 

            // emit ArtifactEdited event
            emit ArtifactEdited(
                msg.sender,
                zoraDrop,
                tokenIds[i],
                artifactDetails[i].artifactRenderer,
                artifactDetails[i].artifactMetadata
            );   
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
        override 
        returns (string memory) 
    {
        string memory uri = contractURIInfo[msg.sender];
        if (bytes(uri).length == 0) {
            // if contractURI return is blank, means the contract has not been initialize
            //      or is being called by an address other than zoraDrop that has been initd
            revert NotInitialized_Or_NotZoraDrop();
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
        override
        returns (string memory)
    {
        string memory uri = IDefaultMetadataDecoder(artifactInfo[msg.sender][tokenId].artifactRenderer).metadataDecoder(artifactInfo[msg.sender][tokenId].artifactMetadata);
        if (bytes(uri).length == 0) revert Token_DoesntExist();
        return uri;
    }    

    /// @notice contractURI + tokenURI information custom getter
    /// @dev reverts if token does not exist
    /// @param zoraDrop to get contractURI for    
    /// @param tokenId to get tokenURI for
    function publisherDirectory(address zoraDrop, uint256 tokenId)
        external
        view
        returns (string memory, string memory)
    {
        
        if (bytes(contractURIInfo[zoraDrop]).length == 0) {
            revert Address_NotInitialized();
        }
        
        if (bytes(contractURIInfo[zoraDrop]).length == 0) {
            return (contractURIInfo[zoraDrop], "");
        }

        return (IMetadataRenderer(zoraDrop).contractURI(), IMetadataRenderer(zoraDrop).tokenURI(tokenId));
    }    
}