// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*


                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.


*/

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IERC721PressFactory} from "./core/interfaces/IERC721PressFactory.sol";
import {IERC721PressLogic} from "./core/interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./core/interfaces/IERC721PressRenderer.sol";
import {IERC721Press} from "./core/interfaces/IERC721Press.sol";
import {ERC721Press} from "./ERC721Press.sol";
import {ERC721PressProxy} from "./core/proxy/ERC721PressProxy.sol";
import {DualOwnableUpgradeable} from "../../core/utils/ownable/dual/DualOwnableUpgradeable.sol";
import {Version} from "../../core/utils/Version.sol";

/**
 * @title ERC721PressFactory
 * @notice A factory contract that deploys an ERC721PressProxy, a UUPS proxy of `ERC721Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721PressFactory is IERC721PressFactory, DualOwnableUpgradeable, UUPSUpgradeable, Version(1) {
    
    /// @notice Implementation contract behind Press proxies
    address public immutable pressImpl;
    
    /// @notice Sets the implementation address upon deployment
    constructor(address _pressImpl) {
        /// Reverts if the given implementation address is zero.
        if (_pressImpl == address(0)) { 
            revert Address_Cannot_Be_Zero();
        }

        pressImpl = _pressImpl;

        emit PressImplementationSet(pressImpl);
    }

    /// @notice Initializes the proxy behind `ERC721PressFactory.sol`
    /// @param _initialOwner The address to set as the initial owner
    /// @param _initialSecondaryOwner The address to set as the initial secondary owner
    function initialize(address _initialOwner, address _initialSecondaryOwner) external initializer {
        // Sets the contract owner to the supplied address
        __Ownable_init(_initialOwner);
        // Sets the secondary contract owner to the supplied address
        __Secondary_Ownable_init(_initialSecondaryOwner);
        /// Initialize UUPS upgradeable functionality
        __UUPSUpgradeable_init();    

        emit PressFactoryInitialized();
    }

    /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
    /// @param name Contract name
    /// @param symbol Contract symbol
    /// @param initialOwner User that owns the contract upon deployment
    /// @param logic Logic contract to use
    /// @param logicInit Logic contract initial data
    /// @param renderer Renderer contract to use
    /// @param rendererInit Renderer initial data
    /// @param soulbound false = tokens in contract are transferrable, true = tokens are non-transferrable
    /// @param configuration see IERC721Press for details  
    function createPress(
        string memory name,
        string memory symbol,
        address initialOwner,
        IERC721PressLogic logic,
        bytes memory logicInit,
        IERC721PressRenderer renderer,
        bytes memory rendererInit,
        bool soulbound,
        IERC721Press.Configuration memory configuration        
    ) public returns (address) {
        /// Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");

        /// Emit creation event from factory
        emit Create721Press({
            newPress: address(newPress),
            creator: msg.sender,
            initialOwner: initialOwner,
            initialLogic: address(logic) ,
            initialRenderer: address(renderer),
            soulbound: soulbound
        });

        /// Initialize the new Press instance
        ERC721Press(payable(address(newPress))).initialize({
            _contractName: name,
            _contractSymbol: symbol,
            _initialOwner: initialOwner,
            _logic: logic,
            _logicInit: logicInit,
            _renderer: renderer,
            _rendererInit: rendererInit,                   
            _soulbound: soulbound,
            _configuration: configuration            
        });

        return address(newPress);
    }

    /// @dev Can be called by the either owner as deifned in DualOwnableUpgradeable
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override eitherOwner {}
}
