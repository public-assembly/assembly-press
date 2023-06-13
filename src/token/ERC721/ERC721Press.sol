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

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

import {IERC721Press} from "./core/interfaces/IERC721Press.sol";
import {IERC721PressLogic} from "./core/interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "./core/interfaces/IERC721PressRenderer.sol";
import {ERC721PressStorageV1} from "./core/storage/ERC721PressStorageV1.sol";

import {IERC5192} from "./core/interfaces/IERC5192.sol";
import {IOwnableUpgradeable} from "../../core/utils/ownable/single/IOwnableUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {OwnableUpgradeable} from "../../core/utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../core/utils/Version.sol";
import {FundsReceiver} from "../../core/utils/FundsReceiver.sol";

/**
 * @title ERC721Press
 * @notice Highly configurable ERC721A implementation
 * @dev Functionality is configurable using external renderer + logic contracts
 * @dev Uses EIP-5192 for optional non-transferrable token implementation
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721Press is
    ERC721AUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Press,
    OwnableUpgradeable,
    Version(1),
    ERC721PressStorageV1,
    FundsReceiver,
    IERC5192
{
    /// @dev Recommended max mint batch size for ERC721A
    uint256 internal immutable MAX_MINT_BATCH_SIZE = 8;

    /// @dev Gas limit to send funds
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    /// @dev Max basis points (BPS) for secondary royalties + primary sales fee
    uint16 constant MAX_BPS = 50_00;

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Initializes a new, creator-owned proxy of ERC721Press.sol
    /// @dev Optional primarySaleFeeBPS + primarySaleFeeRecipient
    ///      + soulbound cannot be adjusted after initialization
    /// @dev initializerERC721A for ERC721AUpgradeable
    ///      initializer` for OpenZeppelin's OwnableUpgradeable
    /// @param _contractName Contract name
    /// @param _contractSymbol Contract symbol
    /// @param _initialOwner User that owns the contract upon deployment
    /// @param _logic Logic contract to use (access control + pricing dynamics)
    /// @param _logicInit Logic contract initial data    
    /// @param _renderer Renderer contract to use    
    /// @param _rendererInit Renderer initial data
    /// @param _soulbound false = tokens in contract are transferrable, true = tokens are non-transferrable
    /// @param _configuration see IERC721Press for details        
    function initialize(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        IERC721PressLogic _logic,
        bytes memory _logicInit,
        IERC721PressRenderer _renderer,            
        bytes memory _rendererInit,
        bool _soulbound,
        Configuration memory _configuration
    ) public initializerERC721A initializer {
        // Setup ERC721A
        __ERC721A_init(_contractName, _contractSymbol);
        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable
        __Ownable_init(_initialOwner);
        // Setup UUPS
        __UUPSUpgradeable_init();        

        // Setup + initialize non-config variables
        _logicImpl = _logic;
        _rendererImpl = _renderer;
        _isSoulbound = _soulbound;
        _logic.initializeWithData(_logicInit);
        _renderer.initializeWithData(_rendererInit);      

        // Check to see if royaltyBPS and feeBPS set to acceptable levels
        if (_configuration.royaltyBPS > MAX_BPS || _configuration.primarySaleFeeBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }           

        // Setup config values
        config.fundsRecipient = _configuration.fundsRecipient;
        config.maxSupply = _configuration.maxSupply;
        config.royaltyBPS = _configuration.royaltyBPS;
        config.primarySaleFeeRecipient = _configuration.primarySaleFeeRecipient;
        config.primarySaleFeeBPS = _configuration.primarySaleFeeBPS;        

        emit IERC721Press.ERC721PressInitialized({
            sender: msg.sender,
            logic: _logic,
            renderer: _renderer,
            fundsRecipient: _configuration.fundsRecipient,
            royaltyBPS: _configuration.royaltyBPS,
            primarySaleFeeRecipient: _configuration.primarySaleFeeRecipient,
            primarySaleFeeBPS: _configuration.primarySaleFeeBPS,
            soulbound: _soulbound
        });        
    }

    // ||||||||||||||||||||||||||||||||
    // ||| MINTING LOGIC ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows user to mint token(s) from the Press contract
    /// @dev mintQuantity is restricted to uint16 even though maxSupply = uint64
    /// @param mintQuantity number of NFTs to mint
    /// @param mintData metadata to associate with the minted token(s)
    function mintWithData(uint64 mintQuantity, bytes calldata mintData)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        // Cache msg.sender + msg.value
        (uint256 msgValue, address sender) = (msg.value, msg.sender);

        // Check to make sure mintQuantity wont takeSupply over maxSupply
        if (_totalMinted() + mintQuantity > config.maxSupply) {
            revert Exceeds_Max_Supply();
        }

        // Call logic contract to check if user can mint
        if (IERC721PressLogic(_logicImpl).canMint(address(this), mintQuantity, sender) != true) {
            revert No_Mint_Access();
        }

        // Call logic contract to check what mintPrice is for given quantity + user
        if (msgValue != IERC721PressLogic(_logicImpl).totalMintPrice(address(this), mintQuantity, sender)) {
            revert Incorrect_Msg_Value();
        }

        // Batch mint NFTs to recipient address
        _mintNFTs(sender, mintQuantity);

        // Cache tokenId of first minted token so tokenId mint range can be reconstituted using events
        uint256 firstMintedTokenId = lastMintedTokenId() - mintQuantity + 1;

        // Update external logic file with data corresponding to this mint
        IERC721PressLogic(_logicImpl).updateLogicWithData(sender, mintData);

        emit IERC721Press.MintWithData({
            recipient: sender,
            quantity: mintQuantity,
            totalMintPrice: msgValue,
            firstMintedTokenId: firstMintedTokenId
        });

        // emit locked events if contract tokens' have been configured as soulbound
        if (_isSoulbound == true) {
            for (uint256 i; i < mintQuantity; ++i) {
                emit Locked(firstMintedTokenId + i);
            }   
        }

        return firstMintedTokenId;
    }

    /// @notice Function to mint NFTs
    /// @dev (Important: Does not enforce max supply limit, enforce that limit earlier)
    /// @dev This batches in size of 8 as recommended by Chiru Labs
    /// @param to address to mint NFTs to
    /// @param quantity number of NFTs to mint
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > MAX_MINT_BATCH_SIZE ? MAX_MINT_BATCH_SIZE : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }

    // // ||||||||||||||||||||||||||||||||
    // // ||| CONFIG ACCESS ||||||||||||||
    // // ||||||||||||||||||||||||||||||||

    /// @notice Function to set config.fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param fundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(address payable fundsRecipient) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (IERC721PressLogic(_logicImpl).canUpdateConfig(address(this), msg.sender) != true) {
            revert No_Config_Access();
        }

        // Update `fundsRecipient` address in config and initialize it
        config.fundsRecipient = fundsRecipient;

        emit UpdatedConfig({
            sender: msg.sender,
            fundsRecipient: fundsRecipient,
            maxSupply: config.maxSupply,
            royaltyBPS: config.royaltyBPS
        }); 
    }

    /// @notice Function to set _logicImpl
    /// @dev Cannot set logic to the zero address
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(IERC721PressLogic newLogic, bytes memory newLogicInit) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (IERC721PressLogic(_logicImpl).canUpdateConfig(address(this), msg.sender) != true) {
            revert No_Config_Access();
        }

        // Update logic contract in config and initialize it
        _logicImpl = newLogic;
        IERC721PressLogic(newLogic).initializeWithData(newLogicInit);

        emit UpdatedLogic({
            sender: msg.sender,
            logic: newLogic
        });
    }

    /// @notice Function to set _rendererImpl
    /// @dev Cannot set renderer to the zero address
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    function setRenderer(IERC721PressRenderer newRenderer, bytes memory newRendererInit) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (IERC721PressLogic(_logicImpl).canUpdateConfig(address(this), msg.sender) != true) {
            revert No_Config_Access();
        }

        // Update renderer in config
        _rendererImpl = newRenderer;
        IERC721PressRenderer(newRenderer).initializeWithData(newRendererInit);

        emit UpdatedRenderer({
            sender: msg.sender,
            renderer: newRenderer
        });
    }

    /// @notice Function to set non logic/renderer values of config
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param fundsRecipient payable address to recieve funds via withdraw
    /// @param maxSupply uint64 value of maxSupply
    /// @param royaltyBPS uint16 value of royaltyBPS
    function setConfig(
        address payable fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    ) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (IERC721PressLogic(_logicImpl).canUpdateConfig(address(this), msg.sender) != true) {
            revert No_Config_Access();
        }
        
        // Run internal _setConfig function and record result
        (bool setSuccess) = _setConfig(
            fundsRecipient,
            maxSupply, 
            royaltyBPS 
        );

        // Check if config update was successful
        if (!setSuccess) {
            revert Set_Config_Fail();
        }

        emit UpdatedConfig({
            sender: msg.sender,
            fundsRecipient: fundsRecipient,
            maxSupply: maxSupply,
            royaltyBPS: royaltyBPS
        });
    }

    /// @notice Internal handler to set config
    function _setConfig(
        address payable fundsRecipient,
        uint64 maxSupply,
        uint16 royaltyBPS
    ) internal returns (bool) {
        // Check if fundsRecipient is the zero address
        _checkForZeroAddress(fundsRecipient);
        // Check if newRoyaltyBPS is higher than immutable MAX_BPS value
        if (royaltyBPS > MAX_BPS) {
            revert Setup_PercentageTooHigh(MAX_BPS);
        }

        // Update fundsRecipient + maxSupply + royaltyBPS
        config.fundsRecipient = fundsRecipient;
        config.maxSupply = maxSupply;        
        config.royaltyBPS = royaltyBPS;

        return true;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| PAYOUTS + ROYALTIES ||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice This withdraws ETH from the contract to the contract owner
    function withdraw() external nonReentrant {
        // Cache msg.sender
        address sender = msg.sender;

        // Check if withdraw is allowed for sender
        if (IERC721PressLogic(_logicImpl).canWithdraw(address(this), sender) != true) {
            revert No_Withdraw_Access();
        }

        // Calculate primary sale fee amount
        uint256 funds = address(this).balance;
        uint256 fee = funds * config.primarySaleFeeBPS / 10_000;

        // Payout primary sale fees
        if (fee > 0) {
            (bool successFee,) = config.primarySaleFeeRecipient.call{value: fee, gas: FUNDS_SEND_GAS_LIMIT}("");
            if (!successFee) {
                revert Withdraw_FundsSendFailure();
            }
            funds -= fee;
        }

        // Payout recipient
        (bool successFunds,) = config.fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
        if (!successFunds) {
            revert Withdraw_FundsSendFailure();
        }

        emit FundsWithdrawn(sender, config.fundsRecipient, funds, config.primarySaleFeeRecipient, fee);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| VIEW CALLS |||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC721Press) returns (address) {
        return super.owner();
    }

    /// @notice Contract uri getter
    /// @dev Call proxies to renderer
    function contractURI() external view returns (string memory) {
        return IERC721PressRenderer(_rendererImpl).contractURI();
    }

    /// @notice Token uri getter
    /// @dev Call proxies to renderer
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) public view override(ERC721AUpgradeable, IERC721Press) returns (string memory) {
        /// Reverts if the supplied token does not exist
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }

        return IERC721PressRenderer(_rendererImpl).tokenURI(tokenId);
    }

    /// @notice Getter for maxSupply value stored in config
    function getMaxSupply() external view returns (uint64) {
        return config.maxSupply;
    }

    /// @notice Getter for fundsRecipent address stored in config
    function getFundsRecipient() external view returns (address payable) {
        return config.fundsRecipient;
    }

    /// @notice Getter for logic contract stored in _logicImpl
    function getLogic() external view returns (IERC721PressLogic) {
        return _logicImpl;
    }

    /// @notice Getter for renderer contract stored in _rendererImpl
    function getRenderer() external view returns (IERC721PressRenderer) {
        return _rendererImpl;
    }

    /// @notice Getter for primarySaleFeeRecipient & BPS details stored in config
    function getPrimarySaleFeeDetails() external view returns (address payable, uint16) {
        return (config.primarySaleFeeRecipient, config.primarySaleFeeBPS);
    }

    /// @notice Getter for contract tokens' non-transferability status
    function isSoulbound() external view returns (bool) {
        return _isSoulbound;
    }

    /// @notice Config details
    /// @return IERC721Press.Configuration details
    function getConfigDetails() external view returns (IERC721Press.Configuration memory) {
        return IERC721Press.Configuration({
            fundsRecipient: config.fundsRecipient,
            maxSupply: config.maxSupply,
            royaltyBPS: config.royaltyBPS,
            primarySaleFeeRecipient: config.primarySaleFeeRecipient,
            primarySaleFeeBPS: config.primarySaleFeeBPS
        });
    }

    function locked(uint256 tokenId) external virtual override(IERC5192, IERC721Press) view returns (bool) {
        // if soulbound == true, return true (IS SOULBOUND)
        if (tokenId > 1000000) return false;
        if (_isSoulbound == true) {
            return true;
        } else {
            return false;
        }
    }     

    /// @dev Get royalty information for token
    /// @param _salePrice sale price for the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override(IERC2981Upgradeable, IERC721Press)
        returns (address receiver, uint256 royaltyAmount)
    {
        if (config.fundsRecipient == address(0)) {
            return (config.fundsRecipient, 0);
        }
        return (config.fundsRecipient, (_salePrice * config.royaltyBPS) / 10_000);
    }

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721AUpgradeable, IERC721Press)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IOwnableUpgradeable).interfaceId == interfaceId
            || type(IERC2981Upgradeable).interfaceId == interfaceId || type(IERC721Press).interfaceId == interfaceId
            || interfaceId == type(IERC5192).interfaceId;                    
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERC721A CUSTOMIZATION ||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice User burn function for tokenId
    /// @param tokenId token id to burn
    function burn(uint256 tokenId) public {
        // Check if burn is allowed for msg.sender
        // Revert if msg.sender is not owner of tokenId AND not granted permission from external logic
        if (
            ERC721Press(payable(address(this))).ownerOf(tokenId) != msg.sender
            && IERC721PressLogic(_logicImpl).canBurn(address(this), tokenId, msg.sender) != true
        ) {
            revert No_Burn_Access();
        }

        // ERC721A _burn approvalCheck set to false to let custom logic take precedence
        _burn(tokenId, false);
    }

    /// @notice User burn function for tokenIds
    /// @param tokenIds token ids to burn
    function burnBatch(uint256[] memory tokenIds) public {
        // For each tokenId, check if burn is allowed for msg.sender
        for (uint256 i; i < tokenIds.length; ++i) {
            // Revert if msg.sender is not owner of tokenId AND not granted permission from external logic
            if (
                ERC721Press(payable(address(this))).ownerOf(tokenIds[i]) != msg.sender
                && IERC721PressLogic(_logicImpl).canBurn(address(this), tokenIds[i], msg.sender) != true
            ) {
                revert No_Burn_Access();
            }            

            _burn(tokenIds[i], false);
        }
    }    

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Getter for last minted token id (gets next token id and subtracts 1)
    /// @dev Also works as a "totalMinted" lookup
    function lastMintedTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
    }

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256) {
        return _numberMinted(ownerAddress);
    }    

    // @notice Getter that returns true if token has been minted and not burned
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);   
    }

    /*
        The following overrdes enable an optional soulbound
        implementation that conforms to EIP-5192
    */

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
        if (_isSoulbound == true) {
            revert Non_Transferrable_Token();
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
        if (_isSoulbound == true) {
            revert Non_Transferrable_Token();
        }
    }    

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
        if (_isSoulbound == true) {
            revert Non_Transferrable_Token();
        }
    }        

    function approve(address approved, uint256 tokenId) public payable override {
        super.approve(approved, tokenId);
        if (_isSoulbound == true) {
            revert Non_Transferrable_Token();
        }        
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        if (_isSoulbound == true) {
            revert Non_Transferrable_Token();
        }        
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
    
    function _checkForZeroAddress(address addressToCheck) internal pure {
        if (addressToCheck == address(0)) {
            revert Cannot_Set_Zero_Address();
        }
    }
}