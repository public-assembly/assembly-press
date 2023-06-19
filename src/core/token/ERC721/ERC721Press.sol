// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

import {IERC721Press} from "./interfaces/IERC721Press.sol";
import {ERC721PressStorageV1} from "./storage/ERC721PressStorageV1.sol";
import {IERC721PressDatabase} from "./interfaces/IERC721PressDatabase.sol";

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {OwnableUpgradeable} from "../../utils/ownable/OwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";
import {TransferUtils} from "../../utils/funds/TransferUtils.sol";

// *
// *
// *
//
// TO DO
// 1. Do New Database Logic Impl
//      this includes doing access, renderer, and sort impl
// 2. Add sort then burn functionality to Press
// Finish Press impl
//
// *
// *
// *

/**
 * @title ERC721Press
 * @notice Configurable ERC721A implementation
 * @dev Functionality is configurable using external logic contract
 * @dev Uses EIP-5192 for optional non-transferrable token implementation
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721Press is
    ERC721AUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Press,
    OwnableUpgradeable,
    Version,
    ERC721PressStorageV1,
    FundsReceiver
{
    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    constructor (IERC721PressDatabase database) {
        _database = database;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Initializes a new, creator-owned proxy of ERC721Press.sol
    /// @dev Token transferrability set in settings cannot be adjusted after initialization
    /// @dev `initializerERC721A` for ERC721AUpgradeable
    ///      `initializer` for OwnableUpgradeable
    /// @param name Contract name
    /// @param symbol Contract symbol
    /// @param initialOwner User that owns the contract upon deployment
    /// @param databaseInit Data to initialize database contract with
    /// @param settings see IERC721Press for details    
    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner,
        bytes calldata databaseInit,
        Settings memory settings
    ) external nonReentrant initializerERC721A initializer {
        // Initialize ERC721A
        __ERC721A_init(name, symbol);
        // Initialize reentrancy guard
        __ReentrancyGuard_init();
        // Initialize owner for Ownable
        __Ownable_init(initialOwner);
        // Initialize UUPS
        __UUPSUpgradeable_init();                      

        // Setup database
        _setDatabase(_database, databaseInit);

        // Check to see if royaltyBPS set to acceptable levels
        if (settings.royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }

        // settings: fundsRecipient, royaltyBPS, token transferability
        _settings = settings;   

        emit SettingsUpdated(msg.sender, settings);  
    }

    // ||||||||||||||||||||||||||||||||
    // ||| WRITE FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /* EXTERNAL */

    /// @notice Allows user to mint token(s) from the Press contract
    /// @dev Allows user to pass in data to be passed into logic contract
    /// @param quantity number of NFTs to mint
    /// @param data data to pass in alongside mint caall
    function mintWithData(uint256 quantity, bytes calldata data)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        // Cache msg.sender + msg.value
        (uint256 msgValue, address sender) = (msg.value, msg.sender);

        // Call logic contract to check user mint access
        if (_database.canMint(address(this), quantity, sender) != true) {
            revert No_Mint_Access();
        }

        // Call logic contract to check totalMintPrice for given quantity * sender
        if (msgValue != _database.totalMintPrice(address(this), quantity, sender)) {
            revert Incorrect_Msg_Value();
        }

        // Route msgValue to fundsRecipient if msgValue doesnt equal 0
        if (msgValue != 0) {
            TransferUtils.safeSendETH(_settings.fundsRecipient, msgValue, TransferUtils._FUNDS_SEND_NORMAL_GAS_LIMIT);
        }

        // Batch mint NFTs to sender address
        _mintNFTs(sender, quantity);

        // Cache tokenId of first minted token so tokenId mint range can be reconstituted in mint event
        uint256 firstMintedTokenId = lastMintedTokenId() - quantity + 1;

        // Update external logic file with data corresponding to this mint
        _database.storeData(data);

        emit IERC721Press.MintWithData({
            recipient: sender,
            quantity: quantity,
            firstMintedTokenId: firstMintedTokenId
        });

        // emit locked events if contract tokens have been configured as non-transferable
        if (_settings.transferable == false) {
            for (uint256 i; i < quantity; ++i) {
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
            uint256 toMint = quantity > _MAX_MINT_BATCH_SIZE ? _MAX_MINT_BATCH_SIZE : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }    

    /// @dev Facilitates z-index style sorting of tokenIds. SortOrders can be positive or negative
    /// @dev Sort orders stored in database contract in mapping for address(this) Press
    /// @param ids tokenIds to store sortOrders for    
    /// @param sortOrders sorting values to store
    function sortTokens(
        uint256[] calldata tokenIds, 
        int96[] calldata sortOrders
    ) external {

        // Cache msg.sender
        (address sender) = msg.sender;

        // Checks if sender has access to sort functionality
        if (_database.canSort(address(this), sender) == false) {
            revert No_Sort_Access();
        }

        // Prevents users from submitting invalid inputs
        if (tokenIds.length != sortOrders.length) {
            revert Invalid_Input_Length();
        }

        // Calls `sortData` function on database contract
        _database.sortData(sender, tokenIds, sortOrders);                
    }

    /// @notice updates the global settings for the ERC721Press contract
    /// @dev transferability stored in settings cannot be updated post contract initialization
    /// @param fundsRecipient global funds recipient
    /// @param royaltyBPS ERC2981 compatible royalty basis points
    function setSettings(address payable fundsRecipient, uint16 royaltyBPS) external {
        // Checks if sender has access to edit Press settings
        if (_database.canEditPayments(address(this), msg.sender) == false) {  
            revert No_Settings_Access();
        }              
        // Check to see if royaltyBPS set to acceptable levels
        if (royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }

        // Update Press settings
        _settings.fundsRecipient = fundsRecipient;
        _settings.royaltyBPS = royaltyBPS;

        emit SettingsUpdated(msg.sender, _settings);  
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| READ FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||    

    /* EXTERNAL */    

    /// @notice Contract uri getter
    /// @dev Call proxies to database
    function contractURI() external view returns (string memory) {
        return IERC721PressDatabase(_database).contractURI();
    }    

    /// @notice Token uri getter
    /// @dev Call proxies to database
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) public view override(ERC721AUpgradeable, IERC721Press) returns (string memory) {
        /// Reverts if the supplied token does not exist
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }

        return IERC721PressDatabase(_database).tokenURI(tokenId);
    }

    /// @notice Getter for last minted token id (gets next token id and subtracts 1)
    /// @dev Also works as a "totalMinted" lookup
    function lastMintedTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
    }        

    function getDatabase() public view returns (address) {
        return _database;
    }

    // @notice Getter that returns true if token has been minted and not burned
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);   
    }    
    
    /* INTERNAL */    

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}