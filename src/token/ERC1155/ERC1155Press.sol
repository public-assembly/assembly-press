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

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../utils/utils/OwnableUpgradeable.sol";
import {Version} from "../../utils/utils/Version.sol";
import {FundsReceiver} from "../../utils/utils/FundsReceiver.sol";
import {IOwnableUpgradeable} from "../../utils/interfaces/IOwnableUpgradeable.sol";
import {IERC1155TokenRenderer} from "./interfaces/IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./interfaces/IERC1155PressContractLogic.sol";
import {IERC1155PressTokenLogic} from "./interfaces/IERC1155PressTokenLogic.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC1155Press} from "./interfaces/IERC1155Press.sol";
import {IERC5633} from "../../utils//interfaces/IERC5633.sol";

/**
 * @title ERC1155Press
 * @notice Highly configurable ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts at both contract and token level
 * @dev Uses EIP-5633 for configurable token level soulbound status
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155,
    Initializable,
    UUPSUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    IERC1155Press,
    OwnableUpgradeable,
    Version(1),
    ERC1155PressStorageV1,
    FundsReceiver,
    IERC5633
{

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTANTS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Max basis points (BPS) for secondary royalties + primary sales fee
    uint16 constant public MAX_BPS = 50_00;

    /// @dev Gas limit to send funds
    uint256 constant internal FUNDS_SEND_GAS_LIMIT = 210_000;    

    /// @dev Max supply value
    uint256 constant internal maxSupply = type(uint256).max;

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Initializes a new, creator-owned proxy of ERC1155Press.sol
    /// @dev `initializer` for OpenZeppelin's OwnableUpgradeable
    /// @param _name Contract name
    /// @param _symbol Contract symbol
    /// @param _initialOwner User that owns the contract upon deployment  
    /// @param _contractLogic Contract level logic contract to use for access control
    /// @param _contractLogicInit Contract level logic optional init data
    function initialize(
        string memory _name, 
        string memory _symbol, 
        address _initialOwner,
        IERC1155PressContractLogic _contractLogic,
        bytes memory _contractLogicInit
    ) public initializer {
        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable 
        __Ownable_init(_initialOwner);

        // Setup contract name + contract symbol. Cannot be updated after initialization
        name = _name;
        symbol = _symbol;

        // Setup + initialize contract level logic
        contractLogic = _contractLogic;
        IERC1155PressContractLogic(_contractLogic).initializeWithData(_contractLogicInit);

        emit ERC1155PressInitialized({
            sender: msg.sender,
            owner: _initialOwner,
            contractLogic: _contractLogic
        });
    }

    // ||||||||||||||||||||||||||||||||
    // ||| MINT FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows user to mint copies of a new tokenId from the Press contract
    /// @dev No ability to update platform fees after setting them in this call
    /// @dev No ability to update token specific soulbound value after setting it in this call
    /// @param recipients address to mint NFTs to
    /// @param quantity number of NFTs to mint to each address
    /// @param logic logic contract to associate with a given token
    /// @param logicInit logicInit data to associate with a given logic contract
    /// @param renderer renderer contracts to associate with a given token
    /// @param rendererInit rendererInit data to associate with a given renderer contract
    /// @param fundsRecipient address that receives funds generated by the token (minus fees) + any secondary royalties
    /// @param royaltyBPS secondary royalty BPS
    /// @param primarySaleFeeRecipient optional primary sale fee recipient address
    /// @param primarySaleFeeBPS primary sale feeBPS. cannot be zero if fee recipient set to != address(0)
    /// @param soulbound determines whether token can be transferred after minted. false = transferrable, true = non-transferrable            
    function mintNew(
        address[] memory recipients,
        uint256 quantity,
        IERC1155PressTokenLogic logic, 
        bytes memory logicInit,
        IERC1155TokenRenderer renderer, 
        bytes memory rendererInit,
        address payable fundsRecipient,
        uint16 royaltyBPS,
        address payable primarySaleFeeRecipient,
        uint16 primarySaleFeeBPS,
        bool soulbound        
    ) external payable nonReentrant {
        // Call contract level logic contract to check if user can mint
        if (IERC1155PressContractLogic(contractLogic).canMintNew(address(this), msg.sender, recipients, quantity) != true) {
            revert No_MintNew_Access();
        }     
        // Call logic contract to check what msg.value needs to be sent for given Press + msg.sender
        if (msg.value != IERC1155PressContractLogic(contractLogic).mintNewPrice(address(this), msg.sender, recipients, quantity)) {
            revert Incorrect_Msg_Value();
        }        
        // Check to see if royaltyBPS and feeBPS set to acceptable levels
        if (royaltyBPS > MAX_BPS || primarySaleFeeBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }
        // Check to see if minted quantity exceeds maxSupply
        if (quantity > maxSupply) {
            revert Exceeds_MaxSupply();
        }        

        // Increment tokenCount for contract. Update global _tokenCount state and sets tokenId to be minted in txn
        ++_tokenCount;

        // Cache _tokenCount value
        uint256 tokenId = _tokenCount;

        // Set token specific logic + renderer contracts
        configInfo[tokenId].logic = logic;
        configInfo[tokenId].renderer = renderer;
        // Set token specific funds recipient + royaltyBPS. Funds recipient address will receive (primary mint revenue - parimary sale fee) + secondary royalties
        configInfo[tokenId].fundsRecipient = fundsRecipient;
        configInfo[tokenId].royaltyBPS = royaltyBPS;
        // Set token specific primry sale fee recipient + feeBPS. Cannot be updated after set 
        configInfo[tokenId].primarySaleFeeRecipient = primarySaleFeeRecipient;        
        configInfo[tokenId].primarySaleFeeBPS = primarySaleFeeBPS;
        // Set token specific soulbound value. false = transferable, true = non-transferable
        configInfo[tokenId].soulbound = soulbound;

        // Initialize token logic + renderer
        IERC1155PressTokenLogic(logic).initializeWithData(tokenId, logicInit);
        IERC1155TokenRenderer(renderer).initializeWithData(tokenId, rendererInit);  

        // For each recipient provided, mint them given quantity of tokenId being newly minted
        for (uint256 i = 0; i < recipients.length; ++i) {
            // Check to see if any recipient is zero address
            if (recipients[i] == address(0)) {
                revert Cannot_Set_Zero_Address();
            }
            // Mint quantity of given tokenId to recipient
            _mint(recipients[i], tokenId, quantity, new bytes(0));

            emit NewTokenMinted({
                tokenId: tokenId,
                sender: msg.sender,
                recipient: recipients[i],
                quantity: quantity
            });            
        }

        // Initialize tokenId => tokenFundsInfo mapping. Even if msg.value is 0, we still want to set it
        tokenFundsInfo[tokenId] = msg.value;      

        // Update tracking of funds associated with given tokenId in tokenFundsInfo
        emit TokenFundsIncreased({
            tokenId: tokenId,
            sender: msg.sender,            
            amount: msg.value
        });
    }

    /// @notice Allows user to mint an existing token from the Press contract
    /// @param tokenId which tokenId to mint copies of
    /// @param recipients addresses to mint NFTs to. multiple recipients allows for gifting
    /// @param quantity how many copies to mint to each recipient
    function mintExisting(         
        uint256 tokenId, 
        address[] memory recipients,
        uint256 quantity
    ) external payable nonReentrant {
        // Cache msg.sender + msg.value
        (uint256 msgValue, address sender) = (msg.value, msg.sender);

        // Check to see if tokenId being minted exists
        if (tokenId > _tokenCount) {
            revert Token_Doesnt_Exist(tokenId);
        }
        // Call token level logic contract to check if user can mint
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canMintExisting(address(this), sender, tokenId, recipients, quantity) != true) {
            revert No_MintExisting_Access();
        }   
        // Call logic contract to check what msg.value needs to be sent for given Press + tokenIds + quantities + msg.sender
        if (msg.value != IERC1155PressTokenLogic(configInfo[tokenId].logic).mintExistingPrice(address(this), tokenId, sender, recipients, quantity)) {
            revert Incorrect_Msg_Value();
        }        
        // Check to see if minted quantity exceeds maxSupply
        if (_totalSupply[tokenId] + quantity > maxSupply) {
            revert Exceeds_MaxSupply();
        }               

        // Mint desired quantity of desired tokenId to each provided recipient
        for (uint256 i; i < recipients.length; ++i) {
            // Mint quantity of given tokenId to recipient
            _mint(recipients[i], tokenId, quantity, new bytes(0));

            emit ExistingTokenMinted({
                tokenId: tokenId,
                sender: sender,
                recipient: recipients[i],
                quantity: quantity
            });    
        }

        // Update tokenId => tokenFundsInfo mapping
        tokenFundsInfo[tokenId] += msgValue;

        // Update tracking of funds associated with given tokenId in tokenFundsInfo
        emit TokenFundsIncreased({
            tokenId: tokenId,
            sender: sender,            
            amount: msgValue
        });        
    }

    /// @notice Allows user to use ERC1155 batch mint call. Helpful for checkout-esque flows
    ///         whre a user is minting multiple different items at once
    /// @param tokenIds tokenIds to mint
    /// @param recipient specific recipient address to batch mint to
    /// @param quantities quantities of tokenIds to mint
    function batchMintExisting(
        uint256[] memory tokenIds,
        address recipient,
        uint256[] memory quantities
    ) external payable nonReentrant {

        // Cache length of tokenIds array
        uint256 newTokens = tokenIds.length;

        // Check if input lengths are correct
        if (newTokens != quantities.length || newTokens == 0) {
            revert Invalid_Input();
        }
        // Check to see if any recipient is zero address
        if (recipient == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Create local value used in msg.value check calculation
        uint256 msgValueCheck;              

        // Do the following access checks 
        for (uint256 i; i < newTokens; ++i) {
            // Check to see if tokenId being minted exists
            if (tokenIds[i] > _tokenCount) {
                revert Token_Doesnt_Exist(tokenIds[i]);
            }
            // Call token level logic contract to check if user can mint
            if (IERC1155PressTokenLogic(configInfo[tokenIds[i]].logic).canMintExisting(address(this), msg.sender, tokenIds[i], _asSingletonArrayAddress(recipient), quantities[i]) != true) {
                revert No_MintExisting_Access();
            }   
            // Check to see if minted quantity exceeds maxSupply
            if (_totalSupply[tokenIds[i]] + quantities[i] > maxSupply) {
                revert Exceeds_MaxSupply();
            }          
            
            // Cache mintExisting Price for this iteration in for loop
            uint256 cachedPrice = IERC1155PressTokenLogic(configInfo[tokenIds[i]].logic).mintExistingPrice(address(this), tokenIds[i], msg.sender, _asSingletonArrayAddress(recipient), quantities[i]);
            // Update tokenId => tokenFundsInfo mapping
            tokenFundsInfo[tokenIds[i]] += cachedPrice;            
            // Add mintExistingPrice for individual token to msgValue chcek    
            msgValueCheck += cachedPrice;
        } 

        // Check if msgValue check is correct
        if (msg.value != msgValueCheck) {
            revert Incorrect_Msg_Value();
        }

        // Process _batchMint call
        _batchMint(recipient, tokenIds, quantities, new bytes(0));

        // Emit event for each token being minted
        for (uint256 i; i < newTokens; ++i) {
            emit ExistingTokenMinted({
                tokenId: tokenIds[i],
                sender: msg.sender,
                recipient: recipient,
                quantity: quantities[i]
            });    
        }        
    }    

    // create an array of length 1
    function _asSingletonArrayAddress(address element) private pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = element;

        return array;
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| BURN FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice User burn function for given tokenId
    /// @param id tokenId to burn
    /// @param amount quantity to burn
    function burn(uint256 id, uint256 amount) public {
        // Check if burn is allowed for sender
        if (IERC1155PressTokenLogic(configInfo[id].logic).canBurn(address(this), id, amount, msg.sender) != true) {
            revert No_Burn_Access();
        }

        _burn(msg.sender, id, amount);
    }

    /// @notice User batch burn function for given tokenIds
    /// @param ids tokenIds to burn
    /// @param amounts quantities to burn
    function batchBurn(uint256[] memory ids, uint256[] memory amounts) public {
        // Cache msg.sender
        address sender = msg.sender;
        
        // prevents users from submitting invalid inputs
        if (ids.length != amounts.length) {
            revert Invalid_Input();
        }        

        // check for burn perimssion for each token
        for (uint256 i; i < ids.length; ++i) {
            // Check if burn is allowed for sender
            if (IERC1155PressTokenLogic(configInfo[ids[i]].logic).canBurn(address(this), ids[i], amounts[i], sender) != true) {
                revert No_Burn_Access();
            }            
        }

        _batchBurn(sender, ids, amounts);
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| ADMIN FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Function to set configInfo[tokenId].fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param tokenId tokenId to target
    /// @param newFundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(uint256 tokenId, address payable newFundsRecipient) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(address(this), tokenId, msg.sender) != true) {
            revert No_Config_Access();
        }

        // Update `fundsRecipient` address in config
        configInfo[tokenId].fundsRecipient = newFundsRecipient;

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: msg.sender, 
            logic: configInfo[tokenId].logic,
            renderer: configInfo[tokenId].renderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }

    /// @notice Function to set configInfo[tokenId].logic
    /// @dev Cannot set `logic` to the zero address
    /// @param tokenId tokenId to target
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(uint256 tokenId, IERC1155PressTokenLogic newLogic, bytes memory newLogicInit) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;        
        // Call logic contract to check is msg.sender can update config for given Press + token
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(address(this), tokenId, sender) != true) {
            revert No_Config_Access();
        }

        // Update logic in config and initialize it
        configInfo[tokenId].logic = newLogic;
        IERC1155PressTokenLogic(configInfo[tokenId].logic).initializeWithData(tokenId, newLogicInit);

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: sender, 
            logic: newLogic,
            renderer: configInfo[tokenId].renderer,
            fundsRecipient: configInfo[tokenId].fundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }    

    /// @notice Function to set configInfo[tokenId].renderer
    /// @dev Cannot set `renderer` to the zero address
    /// @param tokenId tokenId to target
    /// @param newRenderer renderer address to handle general contract renderer
    /// @param newRendererInit data to initialize renderer
    function setRenderer(uint256 tokenId, IERC1155TokenRenderer newRenderer, bytes memory newRendererInit) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;
        // Call logic contract to check is msg.sender can update config for given Press + token
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(address(this), tokenId, sender) != true) {
            revert No_Config_Access();
        }

        // Update renderer in config and initialize it
        configInfo[tokenId].renderer = newRenderer;
        IERC1155TokenRenderer(configInfo[tokenId].renderer).initializeWithData(tokenId, newRendererInit);

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: sender, 
            logic: configInfo[tokenId].logic,
            renderer: newRenderer,
            fundsRecipient: configInfo[tokenId].fundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }    

    /// @notice Function to set config.logic
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param tokenId tokenId to target
    /// @param newFundsRecipient payable address to recieve funds via withdraw
    /// @param newRoyaltyBPS uint16 value of royaltyBPS
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setConfig(
        uint256 tokenId,
        address payable newFundsRecipient,
        uint16 newRoyaltyBPS,
        IERC1155PressTokenLogic newLogic,
        bytes memory newLogicInit,        
        IERC1155TokenRenderer newRenderer,
        bytes memory newRendererInit
    ) external nonReentrant {
        // Call logic contract to check is msg.sender can update config for given Press + token
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(address(this), tokenId, msg.sender) != true) {
            revert No_Config_Access();
        }
        // Store success bool of _setConfig() operation
        (bool setSuccess) = _setConfig(
            tokenId, 
            newFundsRecipient, 
            newRoyaltyBPS, 
            newLogic, 
            newLogicInit, 
            newRenderer, 
            newRendererInit
        );
        // Check if config update was successful
        if (!setSuccess) {
            revert Set_Config_Fail();
        }
        // Fetch soulbound value to avoid stack too deep in event emission
        bool soulboundValue = configInfo[tokenId].soulbound;

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: msg.sender, 
            logic: newLogic,
            renderer: newRenderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: newRoyaltyBPS,
            soulbound: soulboundValue
        });
    }

    /// @notice Internal handler to set config
    function _setConfig(
        uint256 tokenId,
        address payable newFundsRecipient,
        uint16 newRoyaltyBPS,
        IERC1155PressTokenLogic newLogic,
        bytes memory newLogicInit,        
        IERC1155TokenRenderer newRenderer,
        bytes memory newRendererInit
    ) internal returns (bool) {
        // Check if newRoyaltyBPS is higher than immutable MAX_BPS value
        if (newRoyaltyBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }

        // Update fundsRecipient address in config
        configInfo[tokenId].fundsRecipient = newFundsRecipient;
        // Update royaltyBPS in config
        configInfo[tokenId].royaltyBPS = newRoyaltyBPS;
        // Update logic contract address in config + initialize it
        configInfo[tokenId].logic = newLogic;
        newLogic.initializeWithData(tokenId, newLogicInit);
        // Update renderer address in config + initialize it
        configInfo[tokenId].renderer = newRenderer;
        newRenderer.initializeWithData(tokenId, newRendererInit);

        return true;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| CONTRACT OWNERSHIP |||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Set new owner for access control + frontends
    /// @param newOwner address of the new owner
    function setOwner(address newOwner) public {
        // Check if msg.sender can transfer ownership
        if (msg.sender != owner() && IERC1155PressContractLogic(contractLogic).canSetOwner(address(this), msg.sender) != true) {
            revert No_Transfer_Access();
        }

        // Transfer contract ownership to new owner
        _transferOwnership(newOwner);
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNDS WITHDRAWALS ||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows user to withdraw funds generated by a given tokenId to the designated funds recipient for that token
    /// @param tokenId which tokenId to withdraw funds from
    function withdraw(uint256 tokenId) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;
        // Check if withdraw is allowed for sender
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canWithdraw(address(this), tokenId, sender) != true) {
            revert No_Withdraw_Access();
        }
        // Check to see if tokenId has a balance
        if (tokenFundsInfo[tokenId] == 0) {
            revert No_Withdrawable_Balance(tokenId);
        }  

        // Call internal withdraw function
        _withdraw(tokenId, sender);
    }        

    /// @notice Allows user to withdraw funds generated by a given tokenIds to the designated funds recipient for those tokens
    /// @dev reverts if any withdraw call is invalid for any provided tokenId
    /// @param tokenIds which tokenIds to withdraw funds from
    function batchWithdraw(uint256[] memory tokenIds) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;

        // Attempt to process withdraws for each tokenId provided
        for (uint256 i; i < tokenIds.length; ++i) {  
            // Check if withdraw is allowed for sender
            if (IERC1155PressTokenLogic(configInfo[tokenIds[i]].logic).canWithdraw(address(this), tokenIds[i], sender) != true) {
                revert No_Withdraw_Access();
            }
            // Check to see if tokenId has a balance
            if (tokenFundsInfo[tokenIds[i]] == 0) {
                revert No_Withdrawable_Balance(tokenIds[i]);
            }  
            // Call internal withdraw function
            _withdraw(tokenIds[i], sender);
        }
    }    

    /// @notice Withdraws funds generated by a given tokenId to the designated funds recipient for that token
    /// @param tokenId which tokenId to withdraw funds from
    /// @param sender address where withdraw call originated from
    function _withdraw(uint256 tokenId, address sender) internal {
        // check to see if tokenId exists
        if (tokenId > _tokenCount) {
            revert Token_Doesnt_Exist(tokenId);
        }

        // Calculate primary sale fee amount
        uint256 funds = tokenFundsInfo[tokenId];
        uint256 fee = funds * configInfo[tokenId].primarySaleFeeBPS / 10_000;

        // Payout primary sale fees
        if (fee > 0) {
            (bool successFee,) = configInfo[tokenId].primarySaleFeeRecipient.call{value: fee, gas: FUNDS_SEND_GAS_LIMIT}("");
            if (!successFee) {
                revert Withdraw_FundsSendFailure();
            }
            funds -= fee;
        }
        // Payout recipient
        (bool successFunds,) = configInfo[tokenId].fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
        if (!successFunds) {
            revert Withdraw_FundsSendFailure();
        }

        // Update tokenId => tokenFundsInfo mapping
        tokenFundsInfo[tokenId] -= (funds + fee);

        emit TokenFundsWithdrawn({
            tokenId: tokenId, 
            sender: sender, 
            fundsRecipient: configInfo[tokenId].fundsRecipient, 
            fundsAmount: funds, 
            feeRecipient: configInfo[tokenId].primarySaleFeeRecipient, 
            feeAmount: fee
        });
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC1155Press) returns (address) {
        return super.owner();
    }

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) public view virtual override(ERC1155, IERC1155Press) returns (string memory) {
        return IERC1155TokenRenderer(configInfo[tokenId].renderer).uri(tokenId);
    }

    /// @dev Total amount of existing tokens with a given tokenId.
    function totalSupply(uint256 tokenId) external view virtual returns (uint256) {
        return _totalSupply[tokenId];
    }    

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) public view returns (uint256) {
        return _numMinted[tokenId][account];
    }         

    /// @notice getter for internal _tokenCount counter which keeps track of the most recently minted tokenId
    function tokenCount() public view returns (uint256) {
        return _tokenCount;
    }

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic) {
        return IERC1155PressTokenLogic(configInfo[tokenId].logic);
    }    

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155TokenRenderer) {
        return IERC1155TokenRenderer(configInfo[tokenId].renderer);
    }    

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable) {
        return configInfo[tokenId].fundsRecipient;
    }    

    /// @notice Getter for primarySaleFee details stored in configInfo for a given tokenId
    function getPrimarySaleFeeDetails(uint256 tokenId) external view returns (address payable, uint16) {
        return (configInfo[tokenId].primarySaleFeeRecipient, configInfo[tokenId].primarySaleFeeBPS);
    }

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) public view virtual override(IERC1155Press, IERC5633) returns (bool) {
        return configInfo[id].soulbound;
    }       

    /// @notice Config level details
    /// @return Configuration (defined in IERC1155Press) 
    function getConfigDetails(uint256 tokenId) external view returns (Configuration memory) {
        return Configuration({
            logic: configInfo[tokenId].logic,
            renderer: configInfo[tokenId].renderer,
            fundsRecipient: configInfo[tokenId].fundsRecipient,
            royaltyBPS: configInfo[tokenId].royaltyBPS,
            primarySaleFeeRecipient: configInfo[tokenId].primarySaleFeeRecipient,
            primarySaleFeeBPS: configInfo[tokenId].primarySaleFeeBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }      

    /// @dev Get royalty information for token
    /// @param _salePrice Sale price for the token
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override(IERC1155Press, IERC2981Upgradeable)
        returns (address receiver, uint256 royaltyAmount)
    {
        if (configInfo[_tokenId].fundsRecipient == address(0)) {
            return (configInfo[_tokenId].fundsRecipient, 0);
        }
        return (
            configInfo[_tokenId].fundsRecipient,
            (_salePrice * configInfo[_tokenId].royaltyBPS) / 10_000
        );
    }

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, IERC1155Press, ERC1155)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            type(IERC5633).interfaceId == interfaceId;
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| ERC1155 CUSTOMIZATION ||||||
    // ||||||||||||||||||||||||||||||||

    /*
        the following changes to mint/burn calls 
        allow for totalSupply + numMinted to be tracked at the token level
    */

    /// @dev See {ERC1155-_mint}.
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual override {
        super._mint(account, id, amount, data);
        _totalSupply[id] += amount;
        _numMinted[id][account] += amount;
    }

    /// @dev See {ERC1155-_batchMint}.
    function _batchMint(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        super._batchMint(to, ids, amounts, data);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] += amounts[i];
            _numMinted[ids[i]][to] += amounts[i];
            unchecked { ++i; }
        }
    }

    /// @dev See {ERC1155-_burn}.
    function _burn(address account, uint256 id, uint256 amount) internal virtual override {
        super._burn(account, id, amount);
        _totalSupply[id] -= amount;
    }     

    /// @dev See {ERC1155-_batchBurn}.
    function _batchBurn(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual override {
        super._batchBurn(account, ids, amounts);
        for (uint i; i < ids.length;) {
            _totalSupply[ids[i]] -= amounts[i];
            unchecked { ++i; }
        }
    }

    /*
        the following changes enable EIP-5633 style soulbound functionality
    */    

    // override safeTransferFrom hook to calculate array[](1) of tokenId being checked and pass it through
    //      the custom _beforeTokenTransfer soulbound check hook
    function safeTransferFrom(
        address from, 
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes calldata data
    ) public override {
        super.safeTransferFrom(from, to, id, amount, data);
        uint256[] memory ids = _asSingletonArray(id);
        _beforeTokenTransfer(from, to, ids);
    }

    // override safeBatchTransferFrom hook and pass array[] of ids through 
    //      custom _beforeTokenTransfer soulbound check hook
    function safeBatchTransferFrom(
        address from, 
        address to, 
        uint256[] calldata ids, 
        uint256[] calldata amounts, 
        bytes calldata data
    ) public override {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _beforeTokenTransfer(from, to, ids);
    }

    // for single transfers, ids.length will always equal 1
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256[] memory ids
    ) internal virtual {

        for (uint256 i = 0; i < ids.length; ++i) {
            if (isSoulbound(ids[i])) {
                require(
                    from == address(0) || to == address(0),
                    "ERC5633: Soulbound, Non-Transferable"
                );
            }
        }
    }    

    // create an array of length 1
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| UPGRADES |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Can only be called by an admin or the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override canUpgrade {}

    modifier canUpgrade() {
        // call logic contract to check is msg.sender can upgrade
        if (IERC1155PressContractLogic(contractLogic).canUpgrade(address(this), msg.sender) != true && owner() != msg.sender) {
            revert No_Upgrade_Access();
        }

        _;
    }            
}