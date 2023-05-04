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
import {IERC1155PressFactory} from "./core/interfaces/IERC1155PressFactory.sol";
import {IERC1155PressContractLogic} from "./core/interfaces/IERC1155PressContractLogic.sol";
import {ERC1155Press} from "./ERC1155Press.sol";
import {ERC1155PressProxy} from "./core/proxy/ERC1155PressProxy.sol";
import {OwnableUpgradeable} from "../../core/utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../core/utils/Version.sol";

/**
 * @title ERC1155PressFactory
 * @notice A factory contract that deploys an ERC1155PressProxy, a UUPS proxy of `ERC1155Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155PressFactory is IERC1155PressFactory, OwnableUpgradeable, UUPSUpgradeable, Version(1) {
    
    /// @notice Implementation contract behind Press proxies
    address public immutable pressImpl;                

    /// @notice Initializes factory with addresses of implementation logic
    /// @param _pressImpl ERC721Drop logic implementation contract to clone  
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

    /// @notice Creates a new, creator-owned proxy of `ERC1155Press.sol`
    ///  @param name Contract name
    ///  @param symbol Contract symbol
    ///  @param initialOwner User that owns the contract upon deployment
    ///  @param logic Logic contract to use (access control + pricing dynamics)
    ///  @param logicInit Logic contract initial data
    function createPress(
        string memory name,
        string memory symbol,
        address initialOwner,
        IERC1155PressContractLogic logic,
        bytes memory logicInit
    ) public returns (address payable newPressAddress) {
        /// Configure ownership details in proxy constructor
        ERC1155PressProxy newPress = new ERC1155PressProxy(pressImpl, "");

        /// Declare a new variable to track contract creation
        newPressAddress = payable(address(newPress));

        /// Initialize the new Press instance
        ERC1155Press(newPressAddress).initialize({
            _name: name,
            _symbol: symbol,
            _initialOwner: initialOwner,
            _contractLogic: logic,
            _contractLogicInit: logicInit
        });
        
        return newPressAddress;
    }

    /// @dev Can only be called by the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
