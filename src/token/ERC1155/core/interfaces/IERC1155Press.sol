// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

import {IERC1155PressTokenLogic} from "./IERC1155PressTokenLogic.sol";
import {IERC1155PressTokenRenderer} from "./IERC1155PressTokenRenderer.sol";
import {IERC1155PressContractLogic} from "./IERC1155PressContractLogic.sol";
import {IERC1155Skeleton} from "./IERC1155Skeleton.sol";

interface IERC1155Press is IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // stores token level logic + renderer + funds + transferability related information
    struct Configuration {
        address payable fundsRecipient;
        IERC1155PressTokenLogic logic;
        IERC1155PressTokenRenderer renderer;
        address payable primarySaleFeeRecipient;
        bool soulbound;
        uint16 royaltyBPS;
        uint16 primarySaleFeeBPS;        
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint new access for given Press
    error No_MintNew_Access();    
    /// @notice msg.sender does not have mint existing access for given Press
    error No_MintExisting_Access();
    /// @notice msg.sender does not have config access for given Press + tokenId
    error No_Config_Access();     
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    
    /// @notice cannot withdraw balance from a tokenId with no associated funds  
    error No_Withdrawable_Balance(uint256 tokenId);     
    /// @notice msg.sender does not have burn access for given Press + tokenId
    error No_Burn_Access();    
    /// @notice msg.sender does not have owernship transfer access for given Press
    error No_Transfer_Access();       

    // Constraint/invalid/failure errors
    /// @notice invalid input
    error Invalid_Input();
    /// @notice If minted total supply would exceed max supply
    error Exceeds_MaxSupply();    
    /// @notice invalid contract inputs due to parameter.length mismatches
    error Input_Length_Mismatch();
    /// @notice token doesnt exist error
    error Token_Doesnt_Exist(uint256 tokenId);    
    /// @notice incorrect msg.value for transaction
    error Incorrect_Msg_Value();    
    /// @notice cant set address
    error Cannot_Set_Zero_Address();
    /// @notice cannot set royalty or finders fee bps this high
    error Setup_PercentageTooHigh(uint16 maxBPS);    
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();    
    /// @notice error setting config varibles
    error Set_Config_Fail(); 

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Event emitted upon ERC1155Press initialization
    /// @param sender msg.sender calling initialization function
    /// @param owner initial owner of contract
    /// @param contractLogic logic contract set 
    event ERC1155PressInitialized(
        address indexed sender,        
        address indexed owner,
        IERC1155PressContractLogic indexed contractLogic
    );          

    /// @notice Event emitted when minting a new token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintNew function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event NewTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );    

    /// @notice Event emitted when minting an existing token
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender calling mintExisting function
    /// @param recipient recipient of tokens
    /// @param quantity quantity of tokens received by recipient 
    event ExistingTokenMinted(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed recipient,
        uint256 quantity
    );

    /// @notice Event emitted when adding to a tokenId's funds tracking
    /// @param tokenId tokenId being minted
    /// @param sender msg.sender passing value
    /// @param amount value being added to tokenId's funds tracking
    event TokenFundsIncreased(
        uint256 indexed tokenId,        
        address indexed sender,
        uint256 amount
    );    

    /// @notice Event emitted when the funds generated by a given tokenId are withdrawn from the minting contract
    /// @param tokenId tokenId to withdraw generated funds from
    /// @param sender address that issued the withdraw
    /// @param fundsRecipient address that the funds were withdrawn to
    /// @param fundsAmount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event TokenFundsWithdrawn(
        uint256 indexed tokenId,        
        address indexed sender,
        address indexed fundsRecipient,        
        uint256 fundsAmount,
        address feeRecipient,
        uint256 feeAmount
    );    

    /// @notice Event emitted when config is updated post initialization
    /// @param tokenId tokenId config being updated
    /// @param sender address that sent update txn
    /// @param logic logic contract address
    /// @param renderer renderer contract address
    /// @param fundsRecipient fundsRecipient
    /// @param royaltyBPS royaltyBPS
    /// @param soulbound soulbound bool
    event UpdatedConfig(
        uint256 indexed tokenId,
        address indexed sender,        
        IERC1155PressTokenLogic logic,
        IERC1155PressTokenRenderer renderer,
        address fundsRecipient,
        uint16 royaltyBPS,
        bool soulbound
    );    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Public owner setting that can be set by the contract admin
    function owner() external view returns (address);

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) external view returns (string memory);

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic); 

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155PressTokenRenderer); 

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable); 

    /// @notice Config level details
    /// @return Configuration (defined in IERC1155Press) 
    function getConfigDetails(uint256 tokenId) external view returns (Configuration memory);

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
