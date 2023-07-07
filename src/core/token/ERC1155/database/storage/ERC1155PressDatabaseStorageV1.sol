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

import { IERC1155PressDatabase } from "../../interfaces/IERC1155PressDatabase.sol";

/**
 @notice Database storage variables contract
 */
contract ERC1155PressDatabaseStorageV1 {

  /**
  * @notice Press => ID => Pointer to encoded data
  * @dev The first `id` stored will be 0, which means data Ids trail their corresponding
  *       tokenIds by 1
  * @dev Can contain blank/burned entries (not garbage compacted)
  * @dev See IERC1155PressDatabase for details on TokenData struct
  */
  mapping(address => mapping(uint256 => address)) public idToData;

  /**
  * @notice Press => ContractSettings
  * @dev see IERC1155PressDatabase for details on ContractSettings struct
  */
  mapping(address => IERC1155PressDatabase.ContractSettings) public contractSettingsInfo;

  /**
  * @notice Press => TokenId => TokenSettings
  * @dev see IERC155PressDatabase for details on TokenSettings struct
  */
  mapping(address => mapping(uint256 => IERC1155PressDatabase.TokenSettings)) public tokenSettingsInfo;  

  /**
  * @dev Factory address => isOfficial bool
  */
  mapping(address => bool) internal _officialFactories;    
}