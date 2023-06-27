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
import {IERC5192} from "./interfaces/IERC5192.sol";

import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {OwnableUpgradeable} from "../../utils/ownable/OwnableUpgradeable.sol";
import {IOwnableUpgradeable} from "../../utils/ownable/IOwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";
import {TransferUtils} from "../../utils/funds/TransferUtils.sol";

/**
 * @title ERC721Press
 * @notice Configurable ERC721A implementation
 * @dev Functionality is configurable using database contract + init
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

    ////////////////////////////////////////////////////////////
    // INITIALIZER
    ////////////////////////////////////////////////////////////

    /// @notice Initializes a new, creator-owned proxy of ERC721Press.sol
    /// @dev Database Impl + Token transferrability cannot be adjusted after initialization
    /// @dev `initializerERC721A` for ERC721AUpgradeable
    ///      `initializer` for OwnableUpgradeable
    /// @param name Contract name
    /// @param symbol Contract symbol
    /// @param initialOwner User that owns the contract upon deployment
    /// @param database Database implementation address
    /// @param databaseInit Data to initialize database contract with
    /// @param settings see IERC721Press for details    
    function initialize(
        string memory name,
        string memory symbol,
        address initialOwner,
        IERC721PressDatabase database,
        bytes memory databaseInit,
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

        // Set + Initialize Database
        _database = database;
        _database.initializeWithData(databaseInit);
        emit DatabaseImplSet(address(database));        

        // Check to see if royaltyBPS set to acceptable levels
        if (settings.royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }

        // settings: fundsRecipient, royaltyBPS, token transferability
        _settings = settings;   

        emit SettingsUpdated(_msgSenderERC721A(), settings);  
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // MINT
    //////////////////////////////   

    /// @notice Allows user to mint token(s) from the Press contract
    /// @dev Allows user to pass in data to be passed into database contract
    /// @param quantity number of NFTs to mint
    /// @param data data to pass in along side mint call
    function mintWithData(uint256 quantity, bytes calldata data)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        // Cache msg.sender
        address sender = _msgSenderERC721A();

        // Process access + msg value checks + eth transfer (if applicable)
        _mintChecks(sender, quantity, msg.value);

        // `_mintWithData` returns the the firstMintedTokenId of the transaction
        return _mintWithData(sender, quantity, data);
    }

    /// @notice Internal helper that processes process access control + msg.value check + eth transfer (if applicable)
    /// @param sender address of msg.sender 
    /// @param quantity number of NFTs to mint
    /// @param msgValue msgValue to process
    function _mintChecks(address sender, uint256 quantity, uint256 msgValue) internal {
        // Call database contract to check msg.sender mint access
        if (_database.canMint(address(this), sender, quantity) != true) {
            revert No_Mint_Access();
        }
        // Call database contract to check totalMintPrice for given sender * quantity
        if (msgValue != _database.totalMintPrice(address(this), sender, quantity)) {
            revert Incorrect_Msg_Value();
        }        
        // Transfer eth for transaction
        (bool success) = TransferUtils.safeSendETH(
            _settings.fundsRecipient, 
            msgValue, 
            TransferUtils._FUNDS_SEND_NORMAL_GAS_LIMIT
        );
        // Revert if funds transfer not successful
        if (!success) {
            revert Funds_Send_Failure();
        }        
    }

    /// @notice Internal helper that processes mint, data storage, and event emission for mintWithData call
    /// @dev No access checks are present in this function. Enforce elsewhere
    /// @param sender address of msg.sender 
    /// @param quantity number of NFTs to mint
    /// @param data data to pass in along side mint call
    function _mintWithData(address sender, uint256 quantity, bytes calldata data) internal returns (uint256) {
        // Batch mint NFTs to sender address
        _mintNFTs(sender, quantity);
        // Cache tokenId of first minted token so tokenId mint range can be reconstituted in mint event
        uint256 firstMintedTokenId = lastMintedTokenId() - quantity + 1;
        // Update external database with data corresponding to this mint
        _database.storeData(sender, data);    
        // Emit sender + quantity + firstMintedTokenId
        emit IERC721Press.MintWithData({
            sender: sender,
            quantity: quantity,
            firstMintedTokenId: firstMintedTokenId
        });            
        // Emit locked events if contract tokens have been configured as non-transferable
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

    //////////////////////////////
    // SORT
    //////////////////////////////     

    /// @dev Facilitates z-index style sorting of tokenIds. SortOrders can be positive or negative
    /// @dev Sort orders stored in database contract in mapping for address(this) Press
    /// @param tokenIds tokenIds to store sortOrders for    
    /// @param sortOrders sorting values to store
    function sort(
        uint256[] calldata tokenIds, 
        int96[] calldata sortOrders
    ) public {

        // Cache msg.sender
        (address sender) = _msgSenderERC721A();

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

    //////////////////////////////
    // OVERWRITE
    //////////////////////////////  

    /// @dev Facilitates overwriting of data previously associated with a given token
    /// @param tokenIds tokenIds to store new data for 
    /// @param newData array of new byte strings to store for specified tokenIds
    function overwrite(uint256[] memory tokenIds, bytes[] calldata newData) public {

        // Cache msg.sender
        (address sender) = _msgSenderERC721A();    

        // Prevents users from submitting invalid inputs
        if (tokenIds.length != newData.length) {
            revert Invalid_Input_Length();
        }        

        for (uint256 i; i < tokenIds.length; ++i) {
            // Checks if sender has access to update functionality
            if (_database.canEditTokenData(address(this), sender, tokenIds[i]) == false) {
                revert No_Overwrite_Access();
            }
        }

        // Call `overwriteData` function on database contract
        _database.overwriteData(sender, tokenIds, newData);         
    }

    //////////////////////////////
    // BURN
    //////////////////////////////   

    /// @notice User burn function for tokenId
    /// @param tokenId token id to burn
    function burn(uint256 tokenId) public {
        // Cache msg.sender
        address sender = _msgSenderERC721A();
        // Check database contract to + tokenId owner for access
        if (
            ERC721Press(payable(address(this))).ownerOf(tokenId) != sender
            && _database.canBurn(address(this), sender, tokenId) != true
        ) {
            revert No_Burn_Access();
        }        

        // ERC721A _burn approvalCheck set to false to let custom logic take precedence
        _burn(tokenId, false);

        // create array to bass into removeData call
        uint256[] memory tokensToRemove = new uint256[](1);
        tokensToRemove[0] = tokenId;

        // call database to emit removeData event
        _database.removeData(sender, tokensToRemove);        
    }    

    /// @notice User burn batch function for tokenIds
    /// @param tokenIds token ids to burn
    function burnBatch(uint256[] memory tokenIds) public {
        // Cache msg.sender
        address sender = _msgSenderERC721A();        
        // For each tokenId, check if burn is allowed for msg.sender
        for (uint256 i; i < tokenIds.length; ++i) {            
            if (
                ERC721Press(payable(address(this))).ownerOf(tokenIds[i]) != sender
                && _database.canBurn(address(this), sender, tokenIds[i]) != true
            ) {
                revert No_Burn_Access();
            }            

            _burn(tokenIds[i], false);
        }

        // call database to emit removeData event
        _database.removeData(sender, tokenIds);
    }        

    //////////////////////////////
    // MINT_SORT_OVERWRITE_BURN
    //////////////////////////////   
    
    /// @dev Facilitates the processing of mint, sort, overwrite, and burn calls in a single transaction
    /// @param mintParams values to pass into internal mint calls {uint256 quantity, bytes data}
    /// @param sortParams values to pass into sort call {uint256[] tokenIds, int96[] sortOrders}
    /// @param overwriteParams values to pass into overwrite call {uint256[] tokenIds, bytes[] newData}
    /// @param burnParams values to pass into burnBatch call {uint256[] tokenIds}
    function mintSortOverwriteBurn(
        IERC721Press.MintParams calldata mintParams,
        IERC721Press.SortParams calldata sortParams,
        IERC721Press.OverwriteParams calldata overwriteParams,
        IERC721Press.BurnParams calldata burnParams
    ) external payable nonReentrant {
        // Cache msg.sender
        address sender = _msgSenderERC721A();
        // Process mint if non-zero inputs
        if (mintParams.quantity != 0) {
            // Process access + msg value checks + eth transfer (if applicable)
            _mintChecks(sender, mintParams.quantity, msg.value);
            // `mintWithData` processes mint + data storage
            _mintWithData(sender, mintParams.quantity, mintParams.data);
        }
        // Process sort if non-zero inputs        
        if (sortParams.tokenIds.length != 0) {
            sort(sortParams.tokenIds, sortParams.sortOrders); 
        }     
        // Process overwrite if non-zero inputs        
        if (overwriteParams.tokenIds.length != 0) {
            overwrite(overwriteParams.tokenIds, overwriteParams.newData); 
        }     
        // Process burn if non-zero inputs
        if (burnParams.tokenIds.length != 0) {
            burnBatch(burnParams.tokenIds);            
        }
    }        

    //////////////////////////////
    // SETTINGS
    //////////////////////////////     

    /// @notice updates the global settings for the ERC721Press contract
    /// @dev transferability stored in settings cannot be updated post contract initialization
    /// @param fundsRecipient global funds recipient
    /// @param royaltyBPS ERC2981 compatible royalty basis points
    function updateSettings(address payable fundsRecipient, uint16 royaltyBPS) external {
        // Checks if sender has access to edit Press settings
        if (_database.canEditPayments(address(this), _msgSenderERC721A()) == false) {  
            revert No_Settings_Access();
        }              
        // Check to see if royaltyBPS set to acceptable levels
        if (royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }

        // Update Press settings
        _settings.fundsRecipient = fundsRecipient;
        _settings.royaltyBPS = royaltyBPS;

        emit SettingsUpdated(_msgSenderERC721A(), _settings);  
    }    

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // EXTERNAL
    //////////////////////////////   

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC721Press) returns (address) {
        return super.owner();
    }    

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

    /// @notice Getter for databse contract stored in _database
    function getDatabase() public view returns (IERC721PressDatabase) {
        return _database;
    }    

    /// @notice Getter for Press settings stored in _settings
    function getSettings() public view returns (IERC721Press.Settings memory) {
        return IERC721Press.Settings({
            fundsRecipient: _settings.fundsRecipient,
            royaltyBPS: _settings.royaltyBPS,
            transferable: _settings.transferable
        });
    }     

    /// @notice Getter for contract tokens' non-transferability status
    function isSoulbound() external view returns (bool) {
        if (_settings.transferable == true) {
            return false;
        } else {
            return true;
        }
    }    

    /// @notice Getter for last minted token id (gets next token id and subtracts 1)
    /// @dev Also works as a "totalMinted" lookup
    function lastMintedTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
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

    // @notice Getter that returns true if token has been minted and not burned
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);   
    }   

    function locked(uint256 tokenId) external virtual override(IERC5192) view returns (bool) {
        // if transferable = true, return false (IS TRANSFERABLE)
        if (_settings.transferable == true) {
            return false;
        } else {
            return false;
        }
    }         

    /// @dev Get royalty information for token
    /// @param _tokenId the NFT asset queried for royalty information
    /// @param _salePrice the sale price of the NFT asset specified by _tokenId
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override(IERC2981Upgradeable, IERC721Press)
        returns (address receiver, uint256 royaltyAmount)
    {
        if (_settings.fundsRecipient == address(0)) {
            return (_settings.fundsRecipient, 0);
        }
        return (_settings.fundsRecipient, (_salePrice * _settings.royaltyBPS) / 10_000);
    }

    /// @notice Getter that returns number of tokens minted for a given address
    function mintedPerAddress(address minterAddress) external view returns (uint256) {
        return _numberMinted(minterAddress);
    }        
    
    //////////////////////////////
    // INTERNAL
    //////////////////////////////     

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }    

    /// @dev Can only be called by the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}    

    ////////////////////////////////////////////////////////////
    // NON-TRANSFERABLE TOKEN IMPLEMENTATION (EIP-5192)
    ////////////////////////////////////////////////////////////

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }    

    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }        

    function approve(address approved, uint256 tokenId) public payable override {
        super.approve(approved, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }

    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }            
}