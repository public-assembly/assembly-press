// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";

contract ProvenanceRenderer {
    /// @notice struct to store original token details
    struct ProvenanceRecord {
        address contractAddress;
        uint256 tokenId;
        string tokenURI;
        string contractURI;
        bytes32 tokenURIHash;
    }

    mapping(address => ProvenanceRecord) public provenanceByToken;

    /// @notice Default initializer for provenance data
    function initializeWithData(bytes memory data) external {
        // data format: contractAddress, tokenId, tokenURI, contractURI, tokenURIHash
        (
            address contractAddress,
            uint256 tokenId,
            string memory tokenURI,
            string memory contractURI,
            bytes32 tokenURIHash
        ) = abi.decode(data, (address, uint256, string, string, bytes32));

        provenanceByToken[msg.sender] = ProvenanceRecord({
            contractAddress: contractAddress,
            tokenId: tokenId,
            tokenURI: tokenURI,
            contractURI: contractURI,
            tokenURIHash: tokenURIHash
        });
    }

    /// @notice checks whether the provided token contains the original metadata
    function checkProvenance(address tokenToCheck, uint256 tokenId) public returns (bool) {
        if (
            keccak256(abi.encode(ERC721Drop(tokenToCheck).tokenURI(tokenId)))
                != provenanceByToken[tokenToCheck].tokenURIHash
        ) {
            return false;
        }
    }
}
