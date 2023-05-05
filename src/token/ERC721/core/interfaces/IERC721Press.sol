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

import {IERC721PressLogic} from "./IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./IERC721PressRenderer.sol";

interface IERC721Press {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @param _fundsRecipient Address that receives funds from sale
    /// @param _maxSupply uint64 max supply value
    /// @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    /// @param _primarySaleFeeRecipient Funds recipient on primary sales    
    /// @param _primarySaleFeeBPS Optional fee to set on primary sales
    struct Configuration {
        address payable fundsRecipient;
        address payable primarySaleFeeRecipient;
        uint64 maxSupply;
        uint16 royaltyBPS;
        uint16 primarySaleFeeBPS;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint access for given Press
    error No_Mint_Access();
    /// @notice msg.sender does not have config access for given Press
    error No_Config_Access();
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    
    /// @notice msg.sender does not have burn access for given Press
    error No_Burn_Access();

    // Constraint/failure errors
    /// @notice Exceeds maxSupply
    error Exceeds_Max_Supply();
    /// @notice Royalty percentage too high
    error Setup_PercentageTooHigh(uint16 bps);
    /// @notice cannot set address to address(0)
    error Cannot_Set_Zero_Address();
    /// @notice msg.value incorrect for mint call
    error Incorrect_Msg_Value();
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();
    /// @notice error setting config varibles
    error Set_Config_Fail();
    /// @notice error when transferring non-transferrable token
    error Non_Transferrable_Token();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Event emitted if primary sale fee is set during Press initialization
    /// @param feeRecipient address that will recieve primary sale fees
    /// @param feeBPS fee basis points (divide by 10_000 for %)
    event PrimarySaleFeeSet(address indexed feeRecipient, uint16 feeBPS);

    /// @notice Event when Press config is initialized
    /// @param sender address that sent update txn
    /// @param logic address of external logic contract
    /// @param renderer address of external renderer contract
    /// @param fundsRecipient address that will recieve funds stored in Press contract upon withdraw
    /// @param royaltyBPS ERC2981 compliant secondary sales basis points (divide by 10_000 for %)
    /// @param primarySaleFeeRecipient recipient address of optional primary sale fees
    /// @param primarySaleFeeBPS percent BPS of optimal primary sale fee
    /// @param soulbound false = tokens in contract are transferrable, true = non-transferrable
    event ERC721PressInitialized(
        address indexed sender,
        IERC721PressLogic indexed logic,
        IERC721PressRenderer indexed renderer,
        address payable fundsRecipient,
        uint16 royaltyBPS,
        address payable primarySaleFeeRecipient,
        uint16 primarySaleFeeBPS,
        bool soulbound
    );

    /// @notice Event emitted for each mint
    /// @param recipient address nfts were minted to
    /// @param quantity quantity of the minted nfts
    /// @param mintData bytes data passed in with mint
    /// @param totalMintPrice msg.value of mint txn
    /// @param firstMintedTokenId first minted token ID for historic txn detail reconstruction
    event MintWithData(
        address indexed recipient,
        uint256 indexed quantity,
        bytes indexed mintData,
        uint256 totalMintPrice,
        uint256 firstMintedTokenId
    );

    /// @notice Event emitted when the funds are withdrawn from the minting contract
    /// @param withdrawnBy address that issued the withdraw
    /// @param withdrawnTo address that the funds were withdrawn to
    /// @param amount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event FundsWithdrawn(
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount,
        address feeRecipient,
        uint256 feeAmount
    );

    /// @notice Event emitted when logic is updated post initialization
    /// @param sender address that sent update txn
    /// @param logic new logic contract address
    event UpdatedLogic(
        address indexed sender,
        IERC721PressLogic logic 
    );    

    /// @notice Event emitted when renderer is updated post initialization
    /// @param sender address that sent update txn
    /// @param renderer new renderer contract address
    event UpdatedRenderer(
        address indexed sender,
        IERC721PressRenderer renderer
    );        

    /// @notice Event emitted when config is updated post initialization
    /// @param sender address that sent update txn
    /// @param fundsRecipient new fundsRecipient
    /// @param maxSupply new maxSupply
    /// @param royaltyBPS new royaltyBPS
    event UpdatedConfig(
        address indexed sender,
        address fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    );

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice initializes a Press contract instance
    function initialize(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        IERC721PressLogic _logic,
        bytes memory _logicInit,
        IERC721PressRenderer _renderer,
        bytes memory _rendererInit,
        bool _soulbound,
        Configuration memory configuration
    ) external;

    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(uint16 mintQuantity, bytes memory mintData)
        external
        payable
        returns (uint256);

    /// @notice Function to set config.fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param newFundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(address payable newFundsRecipient) external;    

    /// @notice Function to set logic
    /// @dev cannot set logic to address(0)
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(IERC721PressLogic newLogic, bytes memory newLogicInit) external;

    /// @notice Function to set renderer
    /// @dev cannot set renderer to address(0)
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    function setRenderer(IERC721PressRenderer newRenderer, bytes memory newRendererInit) external;

    /// @notice Function to set config
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param fundsRecipient payable address to recieve funds via withdraw
    /// @param maxSupply uint64 value of maxSupply
    /// @param royaltyBPS uint16 value of royaltyBPS
    function setConfig(
        address payable fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    ) external;    

    /// @notice This withdraws ETH from the contract to the contract owner.
    function withdraw() external;

    /// @notice Public owner setting that can be set by the contract admin
    function owner() external view returns (address); 

    /// @notice Contract uri getter
    /// @dev Call proxies to renderer
    function contractURI() external view returns (string memory);

    /// @notice Token uri getter
    /// @dev Call proxies to renderer
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) external view returns (string memory);    

    /// @notice Getter for maxSupply stored in config
    function getMaxSupply() external view returns (uint64);    

    /// @notice Getter for fundsRecipent address stored in config
    function getFundsRecipient() external view returns (address payable);

    /// @notice Getter for renderer contract stored in config
    function getRenderer() external view returns (IERC721PressRenderer);    

    /// @notice Getter for logic contract stored in config
    function getLogic() external view returns (IERC721PressLogic);    

    /// @notice Getter for primarySaleFeeRecipient & BPS details stored in config
    function getPrimarySaleFeeDetails() external view returns (address payable, uint16);    

    /// @notice Getter for contract tokens' non-transferability status
    function isSoulbound() external view returns (bool);

    /// @notice Function to return global config details for the given Press
    function getConfigDetails() external view returns (Configuration memory);       

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) external view returns (bool); 

    /// @dev Get royalty information for token
    /// @param _salePrice sale price for the token
    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);    

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    function lastMintedTokenId() external view returns (uint256);

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256);

    // @notice Getter that returns true if token has been minted and not burned
    function exists(uint256 tokenId) external view returns (bool);    
}
