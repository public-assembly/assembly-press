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

interface IAP721 {
    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    /// @notice Error when msg.sender is not the stored database impl
    error Msg_Sender_Not_Database();
    /// @notice Error when attempting to transfer non-transferrable token
    error Non_Transferrable_Token();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Initializes an AP721 instance
    function initialize(address initialOwner, address database, bytes memory init) external;
    /// @notice Batch-mint tokens to a designated recipient
    function mint(address recipient, uint256 quantity) external;
    /// @notice Burn specific tokenId. Reduces totalSupply
    function burn(uint256 tokenId) external;
    /// @notice Burn multiple tokenIds. Reduces totalSupply
    function burnBatch(uint256[] memory tokenIds) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    /// @notice Getter for AP721 owner
    function owner() external view returns (address);
    /// @notice Contract uri getter
    /// @dev Call proxies to database
    function contractURI() external view returns (string memory);
    /// @notice Token uri getter
    /// @dev Call proxies to database
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) external view returns (string memory);
    /// @dev Get royalty information for token
    /// @param _tokenId the NFT asset queried for royalty information
    /// @param _salePrice the sale price of the NFT asset specified by _tokenId
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
