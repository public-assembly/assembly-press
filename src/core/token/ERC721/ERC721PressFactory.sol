// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {ERC721Press} from "./ERC721Press.sol";
import {ERC721PressProxy} from "./proxy/ERC721PressProxy.sol";
import {IERC721Press} from "./interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "./interfaces/IERC721PressDatabase.sol";
import {IERC721PressFactory} from "./interfaces/IERC721PressFactory.sol";
import {Version} from "../../utils/Version.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title ERC721PressFactory
 * @notice A factory contract that deploys an ERC721PressProxy, a UUPS proxy of `ERC721Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721PressFactory is IERC721PressFactory, Version(1), ReentrancyGuard {

    /// @notice Implementation contract behind Press proxies
    address public immutable pressImpl;

    /// @notice Enshrined database contract passed into each `createPress` call
    address public immutable databaseImpl;    
    
    /// @notice Sets the implementation address upon deployment
    constructor(address _pressImpl, address _databaseImpl) {
        if (_pressImpl == address(0) || _databaseImpl == address(0)) { 
            revert Address_Cannot_Be_Zero();
        }

        pressImpl = _pressImpl;
        databaseImpl = _databaseImpl;

        emit PressImplementationSet(pressImpl);
        emit DatabaseImplementationSet(databaseImpl);
    }

    /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
    /// @param name Contract name
    /// @param symbol Contract symbol
    /// @param initialOwner User that owns the contract upon deployment
    /// @param databaseInit Data to initialize database contract with
    /// @param settings see IERC721Press for details 
    function createPress(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        bytes calldata databaseInit,
        IERC721Press.Settings calldata settings
    ) nonReentrant public returns (address) {
        // Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");
        // Initialize Press in database
        IERC721PressDatabase(databaseImpl).initializePress(address(newPress));
        // Initialize the new Press instance
        ERC721Press(payable(address(newPress))).initialize({
            name: name,
            symbol: symbol,
            initialOwner: initialOwner,
            database: IERC721PressDatabase(databaseImpl),
            databaseInit: databaseInit,
            settings: settings
        });
        // Emit creation event from factory
        emit Create721Press({
            newPress: address(newPress),
            initialOwner: initialOwner,
            databaseImpl: databaseImpl,
            settings: settings
        });        
        return address(newPress);
    }
}