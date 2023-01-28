// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155Press} from "../interfaces/IERC1155Press.sol";
import {IContractLogic} from "../interfaces/IContractLogic.sol";

contract ERC1155PressStorageV1 {
    
    // Contract name + contract symbol
    string public contractName;
    string public contractSymbol;

    /// @notice Contract level logic storage
    IContractLogic public contractLevelLogic;

    /// @notice contract level non transferrable storage value
    uint16 public nonTransferability;

    /// @notice Logic + renderer press contract storage. Stored at tokenId level
    mapping(uint256 => IERC1155Press.Configuration) public configInfo;      

    /// @notice Mapping keeping track of funds generated from mints of a given token 
    mapping(uint256 => uint256) tokenFundsInfo;    

    /// @notice Token level total supply
    mapping(uint256 => uint256) internal _totalSupply;    

}