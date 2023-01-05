// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";

/// @title ERC721PressProxy
contract ERC721PressProxy is ERC1967Proxy {
    /// @notice Setup new proxy for ERC721Press
    /// @param _logic underlying implementation contract
    /// @param _initialOwner initial owner of the underlying contract
    constructor(address _logic, address _initialOwner)
        ERC1967Proxy(_logic, abi.encodeWithSelector(IERC721Press.initialize.selector, _initialOwner));
    {}
}