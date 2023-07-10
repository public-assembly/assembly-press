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

import {IERC1155PressDatabase} from "../interfaces/IERC1155PressDatabase.sol";

contract ERC1155PressStorageV1 {

    ////////////////////////////////////////////////////////////
    // PUBLIC STORAGE
    //////////////////////////////////////////////////////////// 

    /**
    * @notice Contract name
    */
    string public name;
    /**
    * @notice Contract sumbol
    */
    string public symbol;    

    /**
    * @dev Max royalty BPS
    */
    uint16 constant public MAX_ROYALTY_BPS = 50_00;

    ////////////////////////////////////////////////////////////
    // INTERNAL STORAGE
    ////////////////////////////////////////////////////////////

    /**
    * @dev Counter to keep track of tokenId. First token minted will be tokenId #1
    * @dev Can also be used as a num minted lookup
    */
    uint256 internal _tokenCount = 0;
    /**
    * @notice Token level total supply (impacted by burns)
    */
    mapping(uint256 => uint256) internal _totalSupply;           
    /**
    * @notice Token level minted tracker
    */
    mapping(uint256 => mapping(address => uint256)) internal _mintedPerAddress;    

    /**
    * @notice Storage for database impl
    * @dev Set during initialization and cannot be updated
    */
    IERC1155PressDatabase internal _database;
}
