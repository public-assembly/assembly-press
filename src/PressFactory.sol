// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IPressFactory} from "./interfaces/IPressFactory.sol";
import {ILogic} from "./interfaces/ILogic.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";
import {ERC721PressProxy} from "./proxy/ERC721PressProxy.sol";
import {OwnableUpgradeable} from "./utils/OwnableUpgradeable.sol";
import {Version} from "./utils/Version.sol";

/**
 * @title PressFactory
 * @notice A factory contract that deploys a Press, a UUPS proxy of `ERC721Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract PressFactory is 
    IPressFactory,
    OwnableUpgradeable,
    UUPSUpgradeable,
    Version(1)
{
    /// @notice Implementation contract behind Press proxies
    address public immutable pressImpl;

    /// @notice Sets the implementation address upon deployment
    constructor(address _pressImpl) {
        /// Reverts if the given implementation address is zero.
        if (_pressImpl == address(0)) revert Address_Cannot_Be_Zero();

        pressImpl = _pressImpl;

        emit PressInitialized(pressImpl);
    }

    /// @notice Initializes the proxy behind `PressFactory.sol`
    function initialize(address _initialOwner) external initializer {
        /// Sets the contract owner to the supplied address
        __Ownable_init(_initialOwner);

        emit PressFactoryInitialized();
    }

    /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
    ///  @dev optional primarySaleFeeBPS + primarySaleFeeRecipient cannot be adjusted after initialization
    ///  @param _contractName Contract name
    ///  @param _contractSymbol Contract symbol
    ///  @param _initialOwner User that owns the contract upon deployment
    ///  @param _fundsRecipient Wallet address that receives funds from sale
    ///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
    ///  @param _logic Logic contract to use (access control + pricing dynamics)
    ///  @param _logicInit Logic contract initial data
    ///  @param _renderer Renderer contract to use
    ///  @param _rendererInit Renderer initial data
    ///  @param _primarySaleFeeBPS optional fee to set on primary sales
    ///  @param _primarySaleFeeRecipient fundsRecipient on primary sales
    function createPress(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        address payable _fundsRecipient,
        uint16 _royaltyBPS,
        ILogic _logic,
        bytes memory _logicInit,
        IRenderer _renderer,
        bytes memory _rendererInit,
        uint16 _primarySaleFeeBPS,
        address payable _primarySaleFeeRecipient
    ) public returns (address payable newPressAddress) {

        /// Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, _initialOwner);

        /// Declare a new variable to track contract creation
        newPressAddress = payable(address(newPress));

        /// Initialize the new Press instance
        ERC721Press(newPressAddress).initialize({
            _contractName: name,
            _contractSymbol: symbol,
            _initialOwner: defaultAdmin,
            _fundsRecipeint: fundsRecipient,
            _royaltyBPS: royaltyBPS,
            _logic: logic,
            _logicInit: logicInit,
            _renderer: renderer,
            _rendererInit: rendererInit,
            _primarySaleFeeBPS: primarySaleFeeBPS,
            _primarySaleFeeRecipient: primarySaleFeeRecipient
        });
    }

    /// @dev Can only be called by the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyOwner 
    {}
}
