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

import {IERC1155Skeleton} from "./core/interfaces/IERC1155Skeleton.sol";
import {IERC1155Press} from "./core/interfaces/IERC1155Press.sol";
import {IERC1155PressContractLogic} from "./core/interfaces/IERC1155PressContractLogic.sol";
import {IERC1155PressTokenRenderer} from "./core/interfaces/IERC1155PressTokenRenderer.sol";
import {IERC1155PressTokenLogic} from "./core/interfaces/IERC1155PressTokenLogic.sol";

import {ERC1155Skeleton} from "./core/ERC1155Skeleton.sol";
import {ERC1155PressPermissions} from "./core/ERC1155PressPermissions.sol";

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../core/utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../core/utils/Version.sol";

/**
 * @title ERC1155Press
 * @notice Highly configurable ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts at both contract and token level
 * @dev Uses EIP-5633 for optional non-transferrable token implementation
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155Skeleton,
    Version(1),
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC1155Press,
    OwnableUpgradeable,
    ERC1155PressPermissions
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
        _contractLogic.initializeWithData(_contractLogicInit);

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
        IERC1155PressTokenRenderer renderer, 
        bytes memory rendererInit,
        address payable fundsRecipient,
        uint16 royaltyBPS,
        address payable primarySaleFeeRecipient,
        uint16 primarySaleFeeBPS,
        bool soulbound        
    ) external payable nonReentrant {
        // // Call contract level logic contract to check if user can mint
        _canMintNew(address(this), msg.sender, recipients, quantity);
        // // Call logic contract to check what msg.value needs to be sent
        _mintNewValueCheck(msg.value, address(this), msg.sender, recipients, quantity);

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
        IERC1155PressTokenRenderer(renderer).initializeWithData(tokenId, rendererInit);  

        // For each recipient provided, mint them given quantity of tokenId being newly minted
        for (uint256 i = 0; i < recipients.length; ++i) {
            // Check to see if any recipient is zero address
            _checkForZeroAddress(recipients[i]);
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
        _exists(tokenId);
        // Call token level logic contract to check if user can mint
        _canMintExisting(address(this), sender, tokenId, recipients, quantity);
        // Call logic contract to check what msg.value needs to be sent for given Press + tokenIds + quantities + msg.sender
        _mintExistingValueCheck(msgValue, address(this), tokenId, sender, recipients, quantity);
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

    // ||||||||||||||||||||||||||||||||
    // ||| BURN FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice User burn function for given tokenId
    /// @param id tokenId to burn
    /// @param amount quantity to burn
    function burn(uint256 id, uint256 amount) public {    
        // Check if burn is allowed for sender
        _canBurn(address(this), id, amount, msg.sender);

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
            _canBurn(address(this), ids[i], amounts[i], sender);
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
        _canUpdateConfig(address(this), tokenId, msg.sender);

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
        IERC1155PressTokenRenderer newRenderer,
        bytes memory newRendererInit
    ) external nonReentrant {
        // Call logic contract to check is msg.sender can update config for given Press + token
        _canUpdateConfig(address(this), tokenId, msg.sender);
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

        emit UpdatedConfig({
            tokenId: tokenId,
            sender: msg.sender, 
            logic: newLogic,
            renderer: newRenderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: newRoyaltyBPS,
            soulbound: configInfo[tokenId].soulbound
        });
    }

    // ||||||||||||||||||||||||||||||||
    // ||| CONTRACT OWNERSHIP |||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Set new owner for access control + frontends
    /// @param newOwner address of the new owner
    function setOwner(address newOwner) public {
        // Check if msg.sender can transfer ownership
        if (msg.sender != owner() && !contractLogic.canSetOwner(address(this), msg.sender)) {
            revert No_Transfer_Access();
        }

        // Transfer contract ownership to new owner
        _transferOwnership(newOwner);
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNDS WITHDRAWALS ||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Allows user to withdraw funds generated by a given tokenIds to the designated funds recipient for those tokens
    /// @dev reverts if any withdraw call is invalid for any provided tokenId
    /// @param tokenIds which tokenIds to withdraw funds from
    function withdraw(uint256[] memory tokenIds) external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;

        // Attempt to process withdraws for each tokenId provided
        for (uint256 i; i < tokenIds.length; ++i) {  
            // check to see if tokenId exists
            _exists(tokenIds[i]);
            // Check if withdraw is allowed for sender
            _canWithdraw(address(this), tokenIds[i], sender);
            // Check to see if tokenId has a balance
            if (tokenFundsInfo[tokenIds[i]] == 0) {
                revert No_Withdrawable_Balance(tokenIds[i]);
            }  

            // Calculate primary sale fee amount
            uint256 funds = tokenFundsInfo[tokenIds[i]];
            uint256 fee = funds * configInfo[tokenIds[i]].primarySaleFeeBPS / 10_000;

            // Payout primary sale fees
            if (fee > 0) {
                (bool successFee,) = configInfo[tokenIds[i]].primarySaleFeeRecipient.call{value: fee, gas: FUNDS_SEND_GAS_LIMIT}("");
                if (!successFee) {
                    revert Withdraw_FundsSendFailure();
                }
                funds -= fee;
            }
            // Payout recipient
            (bool successFunds,) = configInfo[tokenIds[i]].fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
            if (!successFunds) {
                revert Withdraw_FundsSendFailure();
            }

            // Update tokenIds[i] => tokenFundsInfo mapping
            tokenFundsInfo[tokenIds[i]] -= (funds + fee);

            emit TokenFundsWithdrawn({
                tokenId: tokenIds[i], 
                sender: sender, 
                fundsRecipient: configInfo[tokenIds[i]].fundsRecipient, 
                fundsAmount: funds, 
                feeRecipient: configInfo[tokenIds[i]].primarySaleFeeRecipient, 
                feeAmount: fee
            });
        }
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC1155Press) returns (address) {
        return super.owner();
    }

    /// @notice URI getter for a given tokenId
    function uri(uint256 tokenId) public view virtual override(ERC1155Skeleton, IERC1155Press) returns (string memory) {
        return configInfo[tokenId].renderer.uri(tokenId);
    }

    /// @notice Getter for logic contract stored in configInfo for a given tokenId
    function getTokenLogic(uint256 tokenId) external view returns (IERC1155PressTokenLogic) {
        return configInfo[tokenId].logic;
    }    

    /// @notice Getter for renderer contract stored in configInfo for a given tokenId
    function getRenderer(uint256 tokenId) external view returns (IERC1155PressTokenRenderer) {
        return configInfo[tokenId].renderer;
    }    

    /// @notice Getter for fundsRecipent address stored in configInfo for a given tokenId
    function getFundsRecipient(uint256 tokenId) external view returns (address payable) {
        return configInfo[tokenId].fundsRecipient;
    }    

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) public view virtual override(ERC1155Skeleton, IERC1155Skeleton) returns (bool) {
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

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC1155Press, ERC1155Skeleton)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }        

    // ||||||||||||||||||||||||||||||||
    // ||| UPGRADES |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Can only be called by an admin or the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // ||||||||||||||||||||||||||||||||
    // ||| MISC |||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||    
    
    // Check to see if address = address(0)
    function _checkForZeroAddress(address addressToCheck) internal pure {
        if (addressToCheck == address(0)) {
            revert Cannot_Set_Zero_Address();
        }
    }    

    // Check to see if tokenId being minted exists
    function _exists(uint256 tokenId) internal view {
        if (tokenId > _tokenCount) {
            revert Token_Doesnt_Exist(tokenId);
        }                
    }
}