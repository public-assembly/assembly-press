// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721DropMinterInterface} from "./ERC721DropMinterInterface.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {MetadataRenderAdminCheck} from "zora-drops-contracts/metadata/MetadataRenderAdminCheck.sol";

contract ZorbMinter is MetadataRenderAdminCheck {
    error AlreadyMintedZorbId(uint256);
    error MintedBeyondLimit();
    error DoesNotOwnZorb(address minter, uint256 zorbId);

    event UpdatedMintLimit(address, uint256);

    mapping(address => mapping(address => uint256)) zorbsMintedByContractPerUser;
    mapping(address => mapping(uint256 => bool)) zorbIdMintedByContract;
    mapping(address => uint256) mintLimitOverride;

    address internal immutable zorbContract;

    constructor(address _zorbContract) {
        zorbContract = _zorbContract;
    }

    function mintWithZorbs(address target, uint256[] calldata zorbIds)
        external
    {
        uint256 mintLimit = mintLimitOverride[target];
        // If a mint limit per user is set.
        if (mintLimit > 0) {
            if (
                zorbsMintedByContractPerUser[target][msg.sender] +
                    zorbIds.length >
                mintLimit
            ) {
                revert MintedBeyondLimit();
            }
            zorbsMintedByContractPerUser[target][msg.sender] += zorbIds.length;
        }
        for (uint256 i = 0; i < zorbIds.length; i++) {
            uint256 zorbId = zorbIds[i];
            if (zorbIdMintedByContract[target][zorbId]) {
                revert AlreadyMintedZorbId(zorbId);
            }
            if (IERC721(zorbContract).ownerOf(zorbId) != msg.sender) {
                revert DoesNotOwnZorb(msg.sender, zorbId);
            }
            zorbIdMintedByContract[target][zorbId] = true;
        }
        ERC721DropMinterInterface(target).adminMint(msg.sender, zorbIds.length);
    }

    function setMintLimit(address target, uint256 limit)
        external
        requireSenderAdmin(target)
    {
        mintLimitOverride[target] = limit;
        emit UpdatedMintLimit(target, limit);
    }
}
