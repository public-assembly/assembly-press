// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC721Press {
    
    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    struct Configuration {
        address payable fundsRecipient;
        address logic;
        address renderer;
        uint16 royaltyBPS;
    }

    struct PrimarySaleFee {
        address payable feeRecipient;
        uint16 feeBPS;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    // access errors
    /// @notice msg.sender does not have mint access for given Press       
    error No_Mint_Access();
    /// @notice msg.sender does not have withdraw access for given Press   
    error No_Withdraw_Access();
    /// @notice msg.sender does not have upgrade access for given Press   
    error No_Upgrade_Access();
    /// @notice msg.sender does not have update access for given Press   
    error No_Update_Access();
    /// @notice msg.sender does not have burn access for given Press   
    error No_Burn_Access();
    /// @notice msg.sender does not have transfer access for given Press   
    error No_Transfer_Access();    

    // constraint/failure errors    
    /// @notice Royalty percentage too high
    error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
    /// @notice cannot set address to address(0)
    error Cannot_Set_Zero_Address();    
    /// @notice msg.value incorrect for mint call
    error Incorrect_Msg_Value();
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();
    /// @notice error setting config varibles
    error Set_Config_Fail();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted if primary sale fee is set during Press initialization
    /// @param feeRecipient address that will recieve primary sale fees
    /// @param feeBPS fee basis points (divide by 10_000 for %)
    event PrimarySaleFeeSet(
        address indexed feeRecipient,
        uint16 feeBPS
    );      

    /// @notice Event when Press config is initialized
    /// @param sender address that sent update txn
    /// @param logic address of external logic contract
    /// @param renderer address of external renderer contract
    /// @param fundsRecipient address that will recieve funds stored in Press contract upon withdraw
    /// @param royaltyBPS ERC2981 compliant secondary sales basis points (divide by 10_000 for %)
    event ConfigInitialized(
        address indexed sender,
        address indexed logic,
        address indexed renderer,
        address fundsRecipient,
        uint16 royaltyBPS
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

    /// @notice Event emitted when fundsRecipient is updated post initialization
    /// @param sender address that sent update txn
    /// @param fundsRecipient new fundsRecipient
    event UpdatedFundsRecipient(
        address indexed sender,
        address indexed fundsRecipient
    );          

    /// @notice Event emitted when royaltyBPS is updated post initialization
    /// @param sender address that sent update txn
    /// @param royaltyBPS new royaltyBPS
    event UpdatedRoyaltyBPS(
        address indexed sender,
        uint16 indexed royaltyBPS
    );        

    /// @notice Event emitted when renderer is updated post initialization
    /// @param sender address that sent update txn
    /// @param renderer new renderer contract address
    event UpdatedRenderer(
        address indexed sender,
        address indexed renderer
    );            

    /// @notice Event emitted when logic is updated post initialization
    /// @param sender address that sent update txn
    /// @param logic new logic contract address
    event UpdatedLogic(
        address indexed sender,
        address indexed logic
    );          

    /// @notice Event emitted when config is updated post initialization
    /// @param sender address that sent update txn
    /// @param logic new logic contract address
    /// @param renderer new renderer contract address
    /// @param fundsRecipient new fundsRecipient
    /// @param royaltyBPS new royaltyBPS
    event UpdatedConfig(
        address indexed sender,
        address indexed logic,
        address indexed renderer,
        address fundsRecipient,
        uint16 royaltyBPS
    );         

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(address recipient, uint64 mintQuantity, bytes memory mintData) external payable returns (uint256);

    /// @notice Function to set config.logic
    /// @dev cannot set logic to address(0)
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(address newLogic, bytes memory newLogicInit) external;

    /// @notice Function to set config.renderer
    /// @dev cannot set renderer to address(0)
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    function setRenderer(address newRenderer, bytes memory newRendererInit) external;    

    /// @notice Public owner setting that can be set by the contract admin
    function owner() view external returns (address);

    /// @notice Function to return global config details for the given Press
    function configDetails() external view returns (Configuration memory);

    /// @notice Function to return global primsarySaleFee details for the given Press
    function primarySaleFeeConfig() external view returns (PrimarySaleFee memory);    

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    function lastMintedTokenId() external view returns (uint256);    

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256);

}
