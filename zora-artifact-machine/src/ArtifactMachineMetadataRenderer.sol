// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {IArtifactMachineMetadataRenderer} from "./interfaces/IArtifactMachineMetadataRenderer.sol";
import {IERC721AUpgradeable} from "ERC721A-Upgradeable/IERC721AUpgradeable.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {IERC721MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC721MetadataUpgradeable.sol";
import {MetadataRenderAdminCheck} from "zora-drops-contracts/metadata/MetadataRenderAdminCheck.sol";

import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";

/** 
 * @title ArtifactMachineMetadataRenderer
 * @dev External metadata registry that maps initialized token ids to specific unique tokenURIs
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract ArtifactMachineMetadataRenderer is 
    MetadataRenderAdminCheck,
    IMetadataRenderer, 
    IArtifactMachineMetadataRenderer 
{

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    error No_MetadataAccess();
    error No_WildcardAccess();
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
        address indexed wildcardAddress
    );    

    /// @notice Event for updated WildcardAddress
    event WildcardAddressUpdated(
        address indexed sender,
        address indexed newWildcardAddress
    );    

    // ||||||||||||||||||||||||||||||||
    // ||| VARIABLES ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    /// @notice ContractURI mapping storage
    mapping(address => string) public contractURIInfo;

    /// @notice wildcardAddress mapping storage
    mapping(address => address) public wildcardInfo;

    /// @notice tokenURI mapping storage
    mapping(address => mapping(uint256 => string)) public artifactInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFIERS ||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Modifier to require the sender to be an admin
    /// @param target address that the user wants to modify
    /// @param tokenId uint256 tokenId to check
    modifier metadataAccessCheck(address target, uint256 tokenId ) {
        if ( 
            // check if msg.sender is admin of underlying Zora Drop Contract
            target != msg.sender && !IERC721Drop(target).isAdmin(msg.sender) 
                // check if msg.sender owns specific tokenId 
                && IERC721AUpgradeable(target).ownerOf(tokenId) != msg.sender
                // check if msg.sender is wildcard address for target
                && wildcardInfo[target] != msg.sender
        ) {
            revert No_MetadataAccess();
        }    
        _;
    }         

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL WRITE FUNCTIONS |||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Admin function to update contractURI
    /// @param target target contractURI
    /// @param newContractURI new contractURI
    function updateContractURI(address target, string memory newContractURI)
        external
        requireSenderAdmin(target)
    {
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
    /// @param newTokenURI string new token URI after update
    function updateArtifact(address target, uint256 tokenId, string memory newTokenURI)
        external
    {

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

            _initializeArtifact(target, tokenId, newTokenURI);        
        } else {

            _updateArtifact(target, tokenId, newTokenURI);
        }

        artifactInfo[target][tokenId] = newTokenURI;
    }
    
    /// @notice Admin function to update wildcardAddress
    /// @param target address
    /// @param newWildcardAddress address
    function updateWildcardAddress(address target, address newWildcardAddress)
        external
    {
        if (
            // check if msg.sender is admin of underlying Zora Drop Contract
            target != msg.sender && !IERC721Drop(target).isAdmin(msg.sender)
                // check if msg.sender is wildcard address for target
                && msg.sender != wildcardInfo[target]
        ) {
            revert No_WildcardAccess();
        }

        // check if target collection has been initialized
        if (bytes(contractURIInfo[target]).length == 0) {
            revert Address_NotInitialized();
        }        

        wildcardInfo[target] = newWildcardAddress;

        emit WildcardAddressUpdated({
            sender: msg.sender,
            newWildcardAddress: newWildcardAddress        
        });
    }

    /// @notice Default initializer for collection data from a specific contract
    /// @notice contractURI must be set to non blank string value, 
    /// @param data data to init with
    function initializeWithData(bytes memory data) external {
        // data format: contractURI, wildcardAddress
        (string memory initContractURI, address initWildcard) = abi.decode(data, (string, address));

        // check if contractURI is being set to empty string
        if (bytes(initContractURI).length == 0) {
            revert Cannot_SetBlank();
        }

        contractURIInfo[msg.sender] = initContractURI;

        // wildcardAddress CAN be set to address(0)
        wildcardInfo[msg.sender] = initWildcard;
        
        emit CollectionInitialized({
            target: msg.sender,
            contractURI: initContractURI,
            wildcardAddress: initWildcard
        });
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL WRITE FUNCTIONS |||
    // ||||||||||||||||||||||||||||||||     

    function _initializeArtifact(address target, uint256 tokenId, string memory newTokenURI)
        internal
    {
        artifactInfo[target][tokenId] = newTokenURI;

        emit ArtifactInitialized({
            target: target,
            sender: msg.sender,
            tokenId: tokenId,
            tokenURI: newTokenURI 
        });
    }

    function _updateArtifact(address target, uint256 tokenId, string memory newTokenURI)
        internal
        metadataAccessCheck(target, tokenId)
    {
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