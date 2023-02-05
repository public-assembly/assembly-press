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
import {IERC721PressCreatorV1} from "./interfaces/IERC721PressCreatorV1.sol";
import {IERC721PressLogic} from "./interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./interfaces/IERC721PressRenderer.sol";
import {ERC721PressProxy} from "./proxy/ERC721PressProxy.sol";
import {OwnableUpgradeable} from "../../utils/utils/OwnableUpgradeable.sol";
import {Version} from "../../utils/utils/Version.sol";
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
    ///  @dev Optional `primarySaleFeeBPS` + `primarySaleFeeRecipient` cannot be adjusted after initialization
    ///  @param name Contract name
    ///  @param symbol Contract symbol
    ///  @param defaultAdmin User that owns the contract upon deployment
    ///  @param fundsRecipient Address that receives funds from sale
    ///  @param maxSupply maxSupply value
    ///  @param royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    ///  @param logic Logic contract to use (access control + pricing dynamics)
    ///  @param logicInit Logic contract initial data
    ///  @param renderer Renderer contract to use
    ///  @param rendererInit Renderer initial data
    ///  @param primarySaleFeeBPS Optional fee to set on primary sales
    ///  @param primarySaleFeeRecipient Funds recipient on primary sales
    function createPress(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        address payable fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS,
        IERC721PressLogic logic,
        bytes memory logicInit,
        IERC721PressRenderer renderer,
        bytes memory rendererInit,
        uint16 primarySaleFeeBPS,
        address payable primarySaleFeeRecipient
    ) public {
        /// Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");

        /// Initialize the new Press instance
        ERC721Press(payable(address(newPress))).initialize({
            _contractName: name,
            _contractSymbol: symbol,
            _initialOwner: defaultAdmin,
            _fundsRecipient: fundsRecipient,
            _maxSupply: maxSupply,
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
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
