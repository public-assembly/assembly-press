// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IRenderer} from "../../interfaces/IRenderer.sol";
import {IERC721Press} from "../../interfaces/IERC721Press.sol";
import {ILogic} from "../../interfaces/ILogic.sol";
import {ITokenDecoder} from "../../interfaces/ITokenDecoder.sol";
import {ERC721Press} from "../../ERC721Press.sol";
import {BytecodeStorage} from "../../../../utils/utils/BytecodeStorage.sol";

/**
 @notice EditionRenderer
 @author Max Bochman
 @author Salief Lewis
 */
contract EditionRenderer is IRenderer {
    
    // ===== VARIABLES
    /// @notice event emitted when provenance initialized
    event ArtifactProvenanceRecorded(
        address contractAddress, 
        uint256 tokenId, 
        string artifactContractURI,
        bytes32 contractURIHash,
        string artifactTokenURI, 
        bytes32 tokenURIHash
    );
    
    // ===== VARIABLES
    /// @notice struct to store original token details
    struct ProvenanceRecord {
        address contractAddress;
        uint256 tokenId;
        string artifactContractURI;
        bytes32 contractURIHash;
        string artifactTokenURI;
        bytes32 tokenURIHash;
    }

    // ERRORS
    error NotInitialized_Or_NotPress();
    error Address_NotInitialized();

    mapping(address => ProvenanceRecord) public provenanceInfo;

    /// @notice Default initializer for provenance data
    function initializeWithData(bytes memory data) external {
        // data format: contractAddress, tokenId, tokenURI, contractURI, tokenURIHash
        (
            address contractAddress,
            uint256 tokenId,
            string memory artifactContractURI,
            string memory artifactTokenURI
        ) = abi.decode(data, (address, uint256, string, string));

        bytes32 contractURIHash = keccak256(abi.encode(artifactContractURI));
        
        bytes32 tokenURIHash = keccak256(abi.encode(artifactTokenURI));

        provenanceInfo[msg.sender] = ProvenanceRecord({
            contractAddress: contractAddress,
            tokenId: tokenId,
            artifactContractURI: artifactContractURI,
            contractURIHash: contractURIHash,
            artifactTokenURI: artifactTokenURI,            
            tokenURIHash: tokenURIHash
        });

        emit ArtifactProvenanceRecorded({
            contractAddress: contractAddress,
            tokenId: tokenId,
            artifactContractURI: artifactContractURI,
            contractURIHash: contractURIHash,
            artifactTokenURI: artifactTokenURI,
            tokenURIHash: tokenURIHash            
        });
    }

    /// @notice function doesnt do anything -- since this metadata scheme doesn't require passing data with mint
    function initializeTokenMetadata(bytes memory tokenInit) public {}    

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
        string memory uri = ERC721Press(payable((provenanceInfo[msg.sender].contractAddress))).contractURI();
        if (bytes(uri).length == 0) {
            // if contractURI return is blank, means the contract has not yet been initialized
            //      or is being called by an address other than Press that has been initd
            revert NotInitialized_Or_NotPress();
        }
        return uri;
    }

    /// @notice Token URI information getter
    /// @dev reverts if token does not exist
    /// @return tokenURI uri for given token of collection address (if set)
    function tokenURI(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        string memory uri = ERC721Press(payable((provenanceInfo[msg.sender].contractAddress))).tokenURI(provenanceInfo[msg.sender].tokenId);
        return uri;
    }    

    /// @notice contractURI + tokenURI information custom getter
    /// @dev reverts if token does not exist
    /// @param provenanceContract to get contractURI for    
    function provenanceDirectory(address provenanceContract)
        external
        view
        returns (address, uint256, string memory, bytes32, string memory, bytes32)
    {
        
        if (provenanceInfo[provenanceContract].contractAddress == address(0)) {
            revert Address_NotInitialized();
        }

        return (
            provenanceInfo[provenanceContract].contractAddress,
            provenanceInfo[provenanceContract].tokenId,
            provenanceInfo[provenanceContract].artifactContractURI,
            provenanceInfo[provenanceContract].contractURIHash,
            provenanceInfo[provenanceContract].artifactTokenURI,
            provenanceInfo[provenanceContract].tokenURIHash
        );        
    }        

    /// @notice checks whether the provided contract contains the original metadata
    function checkContractURIProvenance(address artifactContract) external view returns (bool) {
        if (
            keccak256(abi.encode(ERC721Press(payable((artifactContract))).contractURI()))
                != provenanceInfo[artifactContract].contractURIHash
        ) {
            return false;
        }
        return true;
    }

    /// @notice checks whether the provided token contains the original metadata
    function checkTokenURIProvenance(address artifactContract, uint256 tokenId) external view returns (bool) {
        if (
            keccak256(abi.encode(ERC721Press(payable((artifactContract))).tokenURI(tokenId)))
                != provenanceInfo[artifactContract].tokenURIHash
        ) {
            return false;
        }
        return true;
    }    

    /// @notice checks whether the provided contract + token contains the original metadata
    function checkCompleteProvenance(address artifactContract, uint256 tokenId) external view returns (bool) {
        if (
            keccak256(abi.encode(ERC721Press(payable((artifactContract))).contractURI()))
                != provenanceInfo[artifactContract].contractURIHash
            &&
            keccak256(abi.encode(ERC721Press(payable((artifactContract))).tokenURI(tokenId)))
                != provenanceInfo[artifactContract].tokenURIHash
        ) {
            return false;
        }
        return true;
    }        
}
