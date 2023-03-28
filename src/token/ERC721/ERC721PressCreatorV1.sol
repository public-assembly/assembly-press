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
import {IERC721PressCreatorV1} from "./core/interfaces/IERC721PressCreatorV1.sol";
import {IERC721PressLogic} from "./core/interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./core/interfaces/IERC721PressRenderer.sol";
import {IERC721Press} from "./core/interfaces/IERC721Press.sol";
import {ERC721PressProxy} from "./core/proxy/ERC721PressProxy.sol";
import {OwnableUpgradeable} from "../../core/utils/OwnableUpgradeable.sol";
import {Version} from "../../core/utils/Version.sol";
import {ERC721Press} from "./ERC721Press.sol";

/**
 * @title ERC721PressCreatorV1
 * @notice A factory contract that deploys a Press, a UUPS proxy of `ERC721Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721PressCreatorV1 is IERC721PressCreatorV1, OwnableUpgradeable, UUPSUpgradeable, Version(1) {
    /// @notice Implementation contract behind Press proxies
    address public immutable pressImpl;

    /// @notice Logic contract for Curation strategy
    IERC721PressLogic public immutable curatorLogicImpl;    

    /// @notice Metadata renderer contract for Curation strategy
    IERC721PressRenderer public immutable curatorRendererImpl;       

    /// @notice Access control module that creates non-admin controlled open access environment
    address public immutable openAccessImpl;        

    /// @notice recommended IERC721Press.Config params for configuring curaiton contracts
    ///     that are fully open to the public
    IERC721Press.Configuration openCurationConfig = IERC721Press.Configuration({
        fundsRecipient: payable(address(0)),
        maxSupply: type(uint64).max,
        royaltyBPS: 0,
        primarySaleFeeRecipient: payable(address(0)),
        primarySaleFeeBPS: 0
    });    

    /// @notice Sets the implementation address upon deployment
    constructor(address _pressImpl, IERC721PressLogic _curLogImpl, IERC721PressRenderer _curRendImpl, address _openAccessImpl) {
        /// Reverts if the given implementation address is zero.
        if (_pressImpl == address(0) || address(_curLogImpl) == address(0) || address(_curRendImpl) == address(0)) revert Address_Cannot_Be_Zero();

        pressImpl = _pressImpl;

        curatorLogicImpl = _curLogImpl;

        curatorRendererImpl = _curRendImpl;

        openAccessImpl = _openAccessImpl;

        emit PressInitialized(pressImpl);

        emit CurationStrategyInitialized(curatorLogicImpl, curatorRendererImpl, openAccessImpl);
    }

    /// @notice Initializes the proxy behind `PressFactory.sol`
    function initialize(address _initialOwner) external initializer {
        /// Sets the contract owner to the supplied address
        __Ownable_init(_initialOwner);

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

    function createCuration(
        string memory name,
        string memory symbol
    ) public returns (address) {
        /// @notice recommended param used in conjunction with openCurationConfig 
        bytes memory openCurationInit = abi.encode(false, openAccessImpl, ""); 

        /// Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");

        /// Initialize the new Press instance
        ERC721Press(payable(address(newPress))).initialize({
            _contractName: name,
            _contractSymbol: symbol,
            _initialOwner: 0x000000000000000000000000000000000000dEaD,
            _logic: curatorLogicImpl,
            _logicInit: openCurationInit,
            _renderer: curatorRendererImpl,
            _rendererInit: "",                   
            _soulbound: true,
            _configuration: openCurationConfig            
        });        

        return address(newPress);
    }

    /// @dev Can only be called by the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
