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

interface IAP721Logic {
    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Initializes target + initial setup data in logic contract
    function initializeWithData(address target, bytes memory initData) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    /// @notice Getter for contract name
    function name() external view returns (string memory);
    /// @notice Checks if a certain address has store access for a given AP721
    function getStoreAccess(address target, address sender, uint256 quantity) external view returns (bool);
    /// @notice Checks if a certain address has overwrite access for a given AP721 + tokenId
    function getOverwriteAccess(address target, address sender, uint256 tokeknId) external view returns (bool);
    /// @notice Checks if a certain address has remove access for a given AP721 + tokenId
    function getRemoveAccess(address target, address sender, uint256 tokeknId) external view returns (bool);
    /// @notice Checks if a certain address can update the settings for a given AP721
    function getSettingsAccess(address target, address sender) external view returns (bool);
    /// @notice Checks if a certain address get edit contract data post data storage for a given AP721
    function getContractDataAccess(address targetPress, address metadataCaller) external view returns (bool);
}
