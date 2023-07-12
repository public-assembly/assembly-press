// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

interface IERC721PressFactory {

  ////////////////////////////////////////////////////////////
  // EVENTS
  ////////////////////////////////////////////////////////////

  /// @notice Emitted when the underlying Press impl is set in constructor
  event PressImplementationSet(address indexed pressImpl);
  /// @notice Emitted when the underlying Database impl is set in constructor
  event DatabaseImplementationSet(address indexed databaseImpl);
  /// @notice Emitted when a new Press is created
  event Create721Press(
    address indexed newPress,
    address indexed databaseImpl,
    IERC721Press.Settings settings
  );  
  
  ////////////////////////////////////////////////////////////
  // ERRORS
  ////////////////////////////////////////////////////////////

  /// @notice Implementation address cannot be set to zero
  error Address_Cannot_Be_Zero();  
  
  ////////////////////////////////////////////////////////////
  // FUNCTIONS
  ////////////////////////////////////////////////////////////

  /// @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
  function createPress(
    string memory name,
    string memory symbol,
    address initialOwner,
    bytes memory databaseInit,
    IERC721Press.Settings memory settings
  ) external returns (address);
}