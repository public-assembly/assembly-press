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

import {IERC721PressLogic} from "./IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./IERC721PressRenderer.sol";
import {IERC721Press} from "./IERC721Press.sol";

interface IERC721PressCreatorV1 {
  // ||||||||||||||||||||||||||||||||
  // ||| ERRORS |||||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Implementation address cannot be set to zero
  error Address_Cannot_Be_Zero();

  // ||||||||||||||||||||||||||||||||
  // ||| EVENTS |||||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Emitted when a Press instance is initialized
  event PressInitialized(address indexed pressImpl);

  /// @notice Emitted when a Press instance is initialized
  event CurationStrategyInitialized(IERC721PressLogic indexed curLogImpl, IERC721PressRenderer indexed curRendImpl, address indexed openAccessImpl);

  /// @notice Emitted when the PressFactory is initialized
  event PressFactoryInitialized();

  // ||||||||||||||||||||||||||||||||
  // ||| FUNCTIONS ||||||||||||||||||
  // ||||||||||||||||||||||||||||||||

  /// @notice Initializes the proxy behind a PressFactory
  function initialize(address _initialOwner) external;

  /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
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
  ) external returns (address);

  function createCuration(
    string memory name,
    string memory symbol
  ) external returns (address)  ;
}
