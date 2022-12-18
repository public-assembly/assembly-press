// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAssemblyPress} from "./interfaces/IAssemblyPress.sol";

/// @title AssemblyPressProxy
contract AssemblyPressProxy is ERC1967Proxy {
    /// @notice Setup new proxy for AssemblyPress
    /// @param _logic underlying implementation contract
    /// @param _initialOwner initial owner of the underlying contract
    constructor(address _logic, address _initialOwner)
        ERC1967Proxy(_logic, abi.encodeWithSelector(IAssemblyPress.initialize.selector, _initialOwner))
    {}
}
