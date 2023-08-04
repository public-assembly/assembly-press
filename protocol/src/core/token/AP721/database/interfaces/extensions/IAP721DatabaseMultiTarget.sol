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

import {IAP721Database} from "../IAP721Database.sol";

interface IAP721DatabaseMultiTarget is IAP721Database {

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /**
     * @notice Data structure used to input setupAP721Batch args
     */
    struct SetupAP721BatchArgs {
        address initialOwner;
        bytes databaseInit;
        address factory;
        bytes factoryInit;
    }    

    /**
     * @notice Data structure used to input storeMulti args
     */
    struct StoreMultiArgs {
        address target;
        bytes data;
    }    

    /**
     * @notice Data structure used to input overwriteMulti args
     */
    struct OverwriteMultiArgs {
        address target;
        uint256[] tokenIds;
        bytes[] data;
    }    

    /**
     * @notice Data structure used to input overwriteMulti args
     */
    struct RemoveMultiArgs {
        address target;
        uint256[] tokenIds;
    }      

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    /// @notice Facilitates deploy + initialization of multiple, creator-owned proxies of `AP721.sol`
    function setupAP721Batch(SetupAP721BatchArgs[] memory setupAP721BatchArgs) external returns (address[] memory);
    /// @notice Store aribtrary data in database for multiple targets
    function storeMulti(StoreMultiArgs[] memory storeMultiArgs) external;
    /// @notice Overwrite data stored in database for a given token for multiple targets
    function overwriteMulti(OverwriteMultiArgs[] memory overwriteMultiArgs) external;
    /// @notice Erase data stored in database for a given token for multiple targets
    function removeMulti(RemoveMultiArgs[] memory removeMultiArgs) external;
}
