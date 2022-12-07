// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {WildInterface} from "./interfaces/WildInterface.sol";
import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {ERC721DropMinterInterface} from "./interfaces/ERC721DropMinterInterface.sol";
import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";

/** 
 * @title ArtifactMachineMetadataRenderer
 * @dev External metadata registry that maps initialized token ids to specific unique tokenURIs
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract WildRenderer is 
    IMetadataRenderer, 
    WildInterface 
{

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    error No_MetadataAccess();
    error Cannot_SetBlank();
    error Token_DoesntExist();
    error Address_NotInitialized();

    // ||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||
    // ||||||||||||||||||||||||||||    

    /// @notice Event for initialized Artifact
    event ArtifactInitialized(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );    

    /// @notice Event for updated Artifact
    event ArtifactUpdated(
        address indexed target,
        address sender,
        uint256 indexed tokenId,
        string indexed tokenURI
    );

    /// @notice Event for updated contractURI
    event ContractURIUpdated(
        address indexed target,
        address sender,
        string indexed contractURI
    );    

    /// @notice Event for a new collection initialized
    /// @dev admin function indexer feedback
    event CollectionInitialized(
        address indexed target,
        string indexed contractURI,
        address indexed accessControl
    );    

    // ||||||||||||||||||||||||||||||||
    // ||| VARIABLES ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// @notice ContractURI mapping storage
    mapping(address => string) public contractURIInfo;

    /// @notice tokenURI mapping storage
    mapping(address => mapping(uint256 => string)) public artifactInfo;

    // zora contract => access control module in use
    mapping(address => address) public dropToAccessControl;

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL WRITE FUNCTIONS |||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Default initializer for collection data from a specific contract
    /// @notice contractURI must be set to non blank string value 
    /// @param data data to init with
    function initializeWithData(bytes memory data) external {
        // data format: contractURI, accessControl, accessControlInit
        (
            string memory initContractURI, 
            address accessControl, 
            bytes memory accessControlInit
        ) = abi.decode(data, (string, address, bytes));

        // check if contractURI is being set to empty string
        if (bytes(initContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[msg.sender] = initContractURI;

        IAccessControlRegistry(accessControl).initializeWithData(accessControlInit);

        dropToAccessControl[msg.sender] = accessControl;    
        
        emit CollectionInitialized({
            target: msg.sender,
            contractURI: initContractURI,
            accessControl: accessControl
        });
    }   

    /// @notice Admin function to update contractURI
    /// @param target target contractURI
    /// @param newContractURI new contractURI
    function updateContractURI(address target, string memory newContractURI)
        external
    {
        // check if msg.sender has access to update metadata for a token
        if (IAccessControlRegistry(dropToAccessControl[target]).getAccessLevel(address(this), msg.sender) < 2) {
            revert No_MetadataAccess();
        }

        if (bytes(contractURIInfo[target]).length == 0) {
            revert Address_NotInitialized();
        }

        contractURIInfo[target] = newContractURI;

        emit ContractURIUpdated({
            target: target,
            sender: msg.sender,
            contractURI: newContractURI
        });
    }

    /// @notice Admin function to updateArtifact
    /// @param target address which collection to target
    /// @param tokenId uint256 which tokenId to target
    /// @param addressToCheck address address to check access for
    /// @param newTokenURI string new token URI after update
    function updateArtifact(address target, uint256 tokenId, address addressToCheck, string memory newTokenURI)
        external returns (bool)
    {
        // // check to see if token exists
        // if (ERC721DropMinterInterface(target).saleDetails(target).totalMinted < tokenId) {
        //     revert Token_DoesntExist();
        // } 

        // check if target collection has been initialized
        if (bytes(contractURIInfo[target]).length == 0) {
            revert Address_NotInitialized();
        }        

        // check if newTokenURI is empty string
        if (bytes(newTokenURI).length == 0) {
            revert Cannot_SetBlank();
        }

        // check if tokenURI has been set before
        if (bytes(artifactInfo[target][tokenId]).length == 0) {

            _initializeArtifact(target, tokenId, addressToCheck, newTokenURI);        
        } else {

            _updateArtifact(target, tokenId, addressToCheck, newTokenURI);
        }

        artifactInfo[target][tokenId] = newTokenURI;

        return true;
    }              

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL WRITE FUNCTIONS |||
    // ||||||||||||||||||||||||||||||||     

    function _initializeArtifact(address target, uint256 tokenId, address addressToCheck, string memory newTokenURI)
        internal
    {
        // check if msg.sender has access to initialize metadata for a token
        if (IAccessControlRegistry(dropToAccessControl[target]).getAccessLevel(address(this), addressToCheck) < 1) {
            revert No_MetadataAccess();
        }

        artifactInfo[target][tokenId] = newTokenURI;

        emit ArtifactInitialized({
            target: target,
            sender: msg.sender,
            tokenId: tokenId,
            tokenURI: newTokenURI 
        });
    }

    function _updateArtifact(address target, uint256 tokenId, address addressToCheck, string memory newTokenURI)
        internal
    {
        // check if msg.sender has access to update metadata for a token
        if (IAccessControlRegistry(dropToAccessControl[target]).getAccessLevel(address(this), addressToCheck) < 2) {
            revert No_MetadataAccess();
        }

        artifactInfo[target][tokenId] = newTokenURI;

        emit ArtifactUpdated({
            target: target,
            sender: msg.sender,
            tokenId: tokenId,
            tokenURI: newTokenURI 
        });
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
        if (bytes(uri).length == 0) revert Address_NotInitialized();
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
        string memory uri = artifactInfo[msg.sender][tokenId];
        if (bytes(uri).length == 0) revert Token_DoesntExist();
        return artifactInfo[msg.sender][tokenId];
    }
}