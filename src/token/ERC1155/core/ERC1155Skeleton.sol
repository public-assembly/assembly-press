// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {FundsReceiver} from "../../../core/utils/FundsReceiver.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC5633} from "./interfaces/IERC5633.sol";
import {IERC1155Skeleton} from "./interfaces/IERC1155Skeleton.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

/**
 * @title ERC1155Skeleton
 * @notice ERC1155 Skeleton that containing overrides on certain solmate ERC1155 functions
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Skeleton is
    ERC1155,
    ERC1155PressStorageV1,
    FundsReceiver,
    IERC1155Skeleton,
    IERC2981Upgradeable,
    IERC5633
{    

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @dev Total amount of existing tokens with a given tokenId.
    function totalSupply(uint256 tokenId) external view virtual returns (uint256) {
        return _totalSupply[tokenId];
    }    

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) public view returns (uint256) {
        return _numMinted[tokenId][account];
    }         

    /// @notice getter for internal _tokenCount counter which keeps track of the most recently minted tokenId
    function tokenCount() public view returns (uint256) {
        return _tokenCount;
    } 

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) public view virtual override(IERC5633, IERC1155Skeleton) returns (bool) {
        return configInfo[id].soulbound;
    }       

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) public view virtual override(ERC1155) returns (string memory) {}

    /// @dev Get royalty information for token
    /// @param _salePrice Sale price for the token
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override(IERC2981Upgradeable)
        returns (address receiver, uint256 royaltyAmount)
    {
        if (configInfo[_tokenId].fundsRecipient == address(0)) {
            return (configInfo[_tokenId].fundsRecipient, 0);
        }
        return (
            configInfo[_tokenId].fundsRecipient,
            (_salePrice * configInfo[_tokenId].royaltyBPS) / 10_000
        );
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERC1155 CUSTOMIZATION ||||||
    // ||||||||||||||||||||||||||||||||

    /*
        the following changes to mint/burn calls 
        allow for totalSupply + numMinted to be tracked at the token level
    */

    /// @dev See {ERC1155-_mint}.
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
        _numMinted[id][account] += amount;
    }

    /// @dev See {ERC1155-_batchMint}.
    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._batchMint(to, ids, amounts, data);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] += amounts[i];
            _numMinted[ids[i]][to] += amounts[i];
            unchecked { ++i; }
        }
    }

    /// @dev See {ERC1155-_burn}.
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }     

    /// @dev See {ERC1155-_batchBurn}.
    function _batchBurn(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._batchBurn(account, ids, amounts);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] -= amounts[i];
            unchecked { ++i; }
        }
    }

    /*
        the following changes enable EIP-5633 style soulbound functionality
    */    

    // override safeTransferFrom hook to calculate array[](1) of tokenId being checked and pass it through
    //      the custom _beforeTokenTransfer soulbound check hook
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes calldata data
    ) public override {
        super.safeTransferFrom(from, to, id, amount, data);
        uint256[] memory ids = _asSingletonArray(id);
        _beforeTokenTransfer(from, to, ids);
    }

    // override safeBatchTransferFrom hook and pass array[] of ids through 
    //      custom _beforeTokenTransfer soulbound check hook
    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data
    ) public override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _beforeTokenTransfer(from, to, ids);
    }

    // for single transfers, ids.length will always equal 1
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids
    ) internal virtual {

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "ERC5633: Soulbound, Non-Transferable"
                );
            }
        }
    }    

    // create an array of length 1
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }    

    // interfcace
    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        virtual
        view
        override(ERC1155, IERC165Upgradeable)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC5633).interfaceId == interfaceId ||
            type(IERC2981Upgradeable).interfaceId == interfaceId;
    }            
}