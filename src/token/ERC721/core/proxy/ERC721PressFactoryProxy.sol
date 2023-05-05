// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC721PressFactory} from "../interfaces/IERC721PressFactory.sol";

/// @title ERC721PressFactoryProxy
contract ERC721PressFactoryProxy is ERC1967Proxy {
    /// @notice Setup new proxy for ERC721PressFactory
    /// @param _logic underlying implementation contract
    /// @param _initialOwner initial owner of the underlying contract
    /// @param _initialSecondaryOwner initial secondary of the underlying contract
    constructor(address _logic, address _initialOwner, address _initialSecondaryOwner)
        ERC1967Proxy(_logic, abi.encodeWithSelector(IERC721PressFactory.initialize.selector, _initialOwner, _initialSecondaryOwner))
    {}
}