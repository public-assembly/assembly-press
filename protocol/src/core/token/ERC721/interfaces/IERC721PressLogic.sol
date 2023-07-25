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

interface IERC721PressLogic {
    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Sets certain data to be associated with a Press in logic contract
    function initializeWithData(address, bytes memory initData) external;
    /// @notice Checks if a certain address get access mint functionality for a given Press + quantity combination
    function getMintAccess(address targetPress, address mintCaller, uint256 mintQuantity)
        external
        view
        returns (bool);
    /// @notice Checks if a certain address get call the burn function for a given Press
    function getBurnAccess(address targetPress, address burnCaller, uint256 tokenId) external view returns (bool);
    /// @notice Checks if a certain address can update the logic or renderer contract for a given Press
    function getSettingsAccess(address targetPress, address settingsCaller) external view returns (bool);
    /// @notice Checks if a certain address get edit contract data post data storage for a given Press
    function getContractDataAccess(address targetPress, address metadataCaller) external view returns (bool);
    /// @notice Checks if a certain address get edit token data post data storage for a given token for a given Press
    function getTokenDataAccess(address targetPress, address metadataCaller, uint256 tokenId)
        external
        view
        returns (bool);
    /// @notice Checks if a certain address get edit payment settings for a given Press
    function getPaymentsAccess(address targetPress, address txnCaller) external view returns (bool);

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    /// @notice Getter for contract name
    function name() external view returns (string memory);
    /// @notice Calculate totalMintPrice for a given Press, mintCaller, and mintQuantity
    function getMintPrice(address targetPress, address mintCaller, uint256 mintQuantity)
        external
        view
        returns (uint256);
}
