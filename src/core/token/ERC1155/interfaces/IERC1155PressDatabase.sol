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

interface IERC1155PressDatabase {  

  ////////////////////////////////////////////////////////////
  // TYPES
  ////////////////////////////////////////////////////////////

  /**
  * @notice Data structure used to store contract settings in database for a given Press
  * @dev Struct breakdown. Values in parentheses are bytes.
  *
  * First slot: contractLogic (20) = 20 bytes
  * Second slot: contractRenderer (20) + initialized (1) = 21 bytes   
  */
  struct ContractSettings {               
    /// @notice Address of the logic contract
    address contractLogic;                        
    /// @notice Address of the renderer contract
    address contractRenderer;   
    /// @notice Has contract been initialized. 0 = not initialized, 1 = initialized
    uint8 initialized;    
  }        

  /**
  * @notice Data structure used to store token settings in database for a given token + Press
  * @dev Struct breakdown. Values in parentheses are bytes.
  *
  * First slot: fuudsRecipient (20) + royaltyBPS (2) + transferable (1) + tokenInitialized (1) = 24 bytes
  * Second slot: tokenLogic (20) = 20 bytes
  * Third slot: tokenRenderer (20) = 20 bytes   
  */
  struct TokenSettings {               
    /// @notice Address that receives funds from sale
    address payable fundsRecipient;
    /// @notice BPS of the royalty set on the contract. Can be 0 for no royalty
    uint16 royaltyBPS;
    /// @notice Whether or not tokens from this contract can be transferred
    bool transferable;
    /// @notice Has token been initialized. 0 = not initialized, 1 = initialized
    uint8 initialized;
    /// @notice Address of the logic contract
    address tokenLogic;                        
    /// @notice Address of the renderer contract
    address tokenRenderer;   
  }       

  ////////////////////////////////////////////////////////////
  // FUNCTIONS
  ////////////////////////////////////////////////////////////

  //////////////////////////////
  // WRITE FUNCTIONS
  //////////////////////////////      
        
  /// @notice Initializes database with arbitrary data
  function initializeWithData(bytes memory initData) external;      
}