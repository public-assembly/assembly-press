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

interface IAP721DatabaseTypesV1 {

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /**
     * @notice Data structure used to store AP721 config in database
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: fundsRecipient (20) + royaltyBPS (2) + transferable (1) = 23 bytes
     */
    struct AP721Config {
        /// @notice
        address fundsRecipient;
        /// @notice
        uint16 royaltyBPS;
        /// @notice
        bool transferable;
    }

    /**
     * @notice Data structure used to store Press settings in database
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: storageCounter (32) = 32 bytes
     * Second slot: logic (20) + initialized (1) = 21 bytes
     * Third slot: renderer (20) = 20 bytes
     * TODO: confirm that the struct takes up all 32 bytes even if the storage inside of it is less than 32
     * Fourth slot: ap721Config (32) = 32 bytes
     */
    struct Settings {
        /// @notice Keeps track of how many data slots have been filled
        uint256 storageCounter;
        /// @notice Address of the logic contract
        address logic;
        /// @notice initialized uint. 0 = not initialized, 1 = initialized
        uint8 initialized;
        /// @notice Address of the renderer contract
        address renderer;
        /// Stores config settings for AP721 contract
        AP721Config ap721Config;
    }
}
