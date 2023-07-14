// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

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

interface IERC721Press {

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /// @param fundsRecipient Address that receives funds for ERC2981 royalties
    /// @param royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    /// @param transferable Whether or not tokens from this contract can be transferred
    struct Settings {
        address payable fundsRecipient;
        uint16 royaltyBPS;
        bool transferable;
    }

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////  

    /// @notice Event emitted when minting token
    /// @param sender address that called mintWithData
    /// @param quantity numder of tokens to mint
    /// @param firstMintedTokenId first tokenId minted in txn
    event MintWithData(
        address indexed sender,
        uint256 quantity,
        uint256 firstMintedTokenId
    );

    /// @notice Event emitted when settings are updated
    /// @param sender address that sent update txn
    /// @param settings new settings
    event SettingsUpdated(
        address indexed sender,
        Settings settings
    );            

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    // Access errors
    /// @notice msg.sender does not have mint access for given Press
    error No_Mint_Access();
    /// @notice msg.sender does not have burn access for given Press
    error No_Burn_Access();              
    /// @notice msg.sender does not have overwrite access for given Press
    error No_Overwrite_Access();                
    /// @notice msg.sender does not have settings access for given Press
    error No_Settings_Access(); 

    // Constraint & failure errors
    /// @notice msg.value incorrect for mint call
    error Incorrect_Msg_Value();    
    /// @notice Royalty percentage too high
    error Royalty_Percentage_Too_High(uint16 bps);    
    /// @notice Array input lengths don't match
    error Invalid_Input_Length();    
    /// @notice error when attempting to transfer non-transferrable token
    error Non_Transferrable_Token();    
    /// @notice error when failing to send eth
    error Funds_Send_Failure();    

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////    

    /// @notice initializes a Press contract instance
    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner,        
        IERC721PressDatabase database,
        bytes calldata databaseInit,
        Settings memory settings
    ) external;          
    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(uint256 quantity, bytes calldata data) external payable returns (uint256);             
    /// @notice Allows user to overwrite data previously stored with a given token
    function overwrite(uint256[] calldata tokenIds, bytes[] calldata newData) external;           

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////  

    /// @notice Getter for Press owner
    function owner() external view returns (address);    
    /// @notice Contract uri getter
    /// @dev Call proxies to renderer
    function contractURI() external view returns (string memory);
    /// @notice Token uri getter
    /// @dev Call proxies to renderer
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) external view returns (string memory);        
    /// @dev Get royalty information for token
    /// @param _tokenId the NFT asset queried for royalty information
    /// @param _salePrice the sale price of the NFT asset specified by _tokenId    
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);           
    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}