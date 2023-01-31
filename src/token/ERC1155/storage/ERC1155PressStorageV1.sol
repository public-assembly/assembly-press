// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155Press} from "../interfaces/IERC1155Press.sol";
import {IERC1155PressContractLogic} from "../interfaces/IERC1155PressContractLogic.sol";

contract ERC1155PressStorageV1 {    
    /// @dev Counter to keep track of tokenId. First token minted will be tokenId #1
    uint256 internal _tokenCount = 0;
    /// @notice Contract name
    string public contractName;
    /// @notice Contract sumbol
    string public contractSymbol;
    /// @notice Contract level logic storage
    IERC1155PressContractLogic public contractLogic;
    /// @notice contract level non transferrable storage value
    uint16 public nonTransferability;
    /// @notice Logic + renderer press contract storage. Stored at tokenId level
    mapping(uint256 => IERC1155Press.Configuration) public configInfo;      
    /// @notice Mapping keeping track of funds generated from mints of a given token 
    mapping(uint256 => uint256) tokenFundsInfo;    
    /// @notice Token level total supply
    mapping(uint256 => uint256) internal _totalSupply;    
    /// @notice Token level minted tracker
    mapping(uint256 => mapping(address => uint256)) internal _numMinted;        
    // Token level isSoulbound value mapping
    mapping(uint256 => bool) internal _soulboundInfo;    
}