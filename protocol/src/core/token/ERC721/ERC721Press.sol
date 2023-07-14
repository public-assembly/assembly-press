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

import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC721Press} from "./interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "./interfaces/IERC721PressDatabase.sol";
import {IERC5192} from "./interfaces/IERC5192.sol";
import {ERC721PressStorageV1} from "./storage/ERC721PressStorageV1.sol";

import {IOwnableUpgradeable} from "../../utils/ownable/single/IOwnableUpgradeable.sol";
import {OwnableUpgradeable} from "../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";
import {TransferUtils} from "../../utils/TransferUtils.sol";

/**
 * @title ERC721Press
 * @notice Configurable ERC721A implementation
 * @dev Functionality configurable via database contract + init
 * @dev Uses EIP-5192 for (optional) non-transferrable token implementation
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

    /**
    * @notice Initializes a new, creator-owned proxy of ERC721Press.sol
    * @dev Database implementation + token transferrability cannot be adjusted after initialization
    * @dev `initializerERC721A` for ERC721AUpgradeable
    *      `initializer` for OwnableUpgradeable
    * @param name Contract name
    * @param symbol Contract symbol
    * @param initialOwner User that owns the contract upon deployment
    * @param database Database implementation address
    * @param databaseInit Data to initialize database contract with
    * @param settings See IERC721Press for details   
    */  
    function initialize(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        IERC721PressDatabase database,
        bytes calldata databaseInit,
        Settings calldata settings
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

        // Check royaltyBPS for acceptable value
        if (settings.royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }

        // Initialize settings: {fundsRecipient, royaltyBPS, token transferability}
        _settings = settings;   
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // MINT
    //////////////////////////////   

    /**
    * @notice Allows user to mint token(s) from the Press contract
    * @dev Sends data to be stored in database contract (optional)
    * @param quantity Number of NFTs to mint
    * @param data Data to send in transaction (optional)
    * @return firstMintedTokenId First tokenId minted during transaction
    */    
    function mintWithData(uint256 quantity, bytes calldata data)
        external
        payable
        nonReentrant
        returns (uint256 firstMintedTokenId)
    {
        // Cache msg.sender
        address sender = _msgSenderERC721A();

        // Process access & msg.value checks + ETH transfer (if applicable)
        _mintChecks(sender, quantity, msg.value);

        // `_mintWithData` returns the the firstMintedTokenId of the transaction
        return _mintWithData(sender, quantity, data);
    }

    /**
    * @notice Internal helper that processes access & msg.value checks + ETH transfer (if applicable)
    * @param sender Address of msg.sender 
    * @param quantity Number of NFTs to mint
    * @param msgValue Msg.value to process
    */
    function _mintChecks(address sender, uint256 quantity, uint256 msgValue) internal {
        // Request sender mint access from database contract
        if (_database.canMint(address(this), sender, quantity) != true) {
            revert No_Mint_Access();
        }    
        // Request storageFee for given sender * quantity from database contract
        (address storageFeeRecipient, uint256 storageFee) = _database.getStorageFee(address(this), sender, quantity);
        if (msgValue != storageFee) {
            revert Incorrect_Msg_Value();
        }     
        // Process ETH transfer for transaction (if applicable)
        (bool success) = TransferUtils.safeSendETH(
            storageFeeRecipient,
            msgValue, 
            TransferUtils._FUNDS_SEND_NORMAL_GAS_LIMIT
        );
        // Revert if ETH transfer not successful
        if (!success) {
            revert Funds_Send_Failure();
        }        
    }

    /**
    * @notice Internal helper that processes mint, data storage, & event emission for `mintWithData`
    * @dev No access checks present in this function. Enforce elsewhere
    * @param sender Address of msg.sender 
    * @param quantity Number of NFTs to mint
    * @param data Data to send in transaction (optional)
    * @return firstMintedTokenId First tokenId minted during transaction
    */
    function _mintWithData(address sender, uint256 quantity, bytes calldata data) internal returns (uint256) {
        // Batch mint NFTs to sender address
        _mintNFTs(sender, quantity);
        // Cache tokenId of first minted token 
        uint256 firstMintedTokenId = lastMintedTokenId() - quantity + 1;
        // Update database with data included in `mintWithData` call
        _database.storeData(sender, data);    

        emit IERC721Press.MintWithData({
            sender: sender,
            quantity: quantity,
            firstMintedTokenId: firstMintedTokenId
        });            
        
        // Emit locked events if contract's tokens were initialized as non-transferable
        if (_settings.transferable == false) {
            for (uint256 i; i < quantity; ++i) {
                emit Locked(firstMintedTokenId + i);
            }   
        }        
        return firstMintedTokenId;
    }

    /**
    * @notice Internal helper to mint NFTs
    * @dev Does not enforce max supply limit, enforce that limit earlier (if applicable)
    * @dev This batches in size of 8 as recommended by Chiru Labs
    * @param to Address to mint NFTs to
    * @param quantity Number of NFTs to mint
    */
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > _MAX_MINT_BATCH_SIZE ? _MAX_MINT_BATCH_SIZE : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }        

    //////////////////////////////
    // OVERWRITE
    //////////////////////////////  

    /**
    * @notice Facilitates overwriting of data previously stored for a given token
    * @dev Does not affect sort values for tokens being overwritten
    * @param tokenIds TokenIds to overwrite data for 
    * @param newData Array of bytes strings to overwrite existing token data with
    */
    function overwrite(uint256[] calldata tokenIds, bytes[] calldata newData) public {
        // Cache msg.sender
        (address sender) = _msgSenderERC721A();    

        for (uint256 i; i < tokenIds.length; ++i) {
            // Request token overwrite access from database
            if (_database.canEditTokenData(address(this), sender, tokenIds[i]) == false) {
                revert No_Overwrite_Access();
            }
        }

        // Update database with newData
        _database.overwriteData(sender, tokenIds, newData);         
    }

    //////////////////////////////
    // BURN
    //////////////////////////////   

    /**
    * @notice User burn function for tokenId
    * @dev Triggers an event from database but does not actually delete stored data
    * @dev Data for burned tokens is skipped in database `readData` + `readAllData` calls
    * @param tokenId TokenId to burn
    */
    function burn(uint256 tokenId) public {
        // Cache msg.sender
        address sender = _msgSenderERC721A();

        // Request burn access from database +
        //      check if msg.sender owns tokenId
        if (
            ERC721Press(payable(address(this))).ownerOf(tokenId) != sender
            && _database.canBurn(address(this), sender, tokenId) != true
        ) {
            revert No_Burn_Access();
        }        

        // ERC721A _burn approvalCheck set to false to let custom logic take precedence
        _burn(tokenId, false);

        // Create tokenId array to pass into `removeData` call
        uint256[] memory tokensToRemove = new uint256[](1);
        tokensToRemove[0] = tokenId;

        // Call database to emit `DataRemoved` event
        _database.removeData(sender, tokensToRemove);        
    }    

    /**
    * @notice User burn function for burning multiple tokenIds at once
    * @dev Triggers a events from database but does not actually delete stored data
    * @dev Data for burned tokens is skipped in database `readData` + `readAllData` calls
    * @param tokenIds TokenIds to burn
    */    
    function burnBatch(uint256[] memory tokenIds) public {
        // Cache msg.sender
        address sender = _msgSenderERC721A();        

        // For each tokenId, request burn access from database +
        //      check if msg.sender owns tokenId        
        for (uint256 i; i < tokenIds.length; ++i) {            
            if (
                ERC721Press(payable(address(this))).ownerOf(tokenIds[i]) != sender
                && _database.canBurn(address(this), sender, tokenIds[i]) != true
            ) {
                revert No_Burn_Access();
            }            

            _burn(tokenIds[i], false);
        }

        // Call database to emit `DataRemoved` event
        _database.removeData(sender, tokenIds);
    }               

    //////////////////////////////
    // SETTINGS
    //////////////////////////////     

    /**
    * @notice Updates global settings for Press contract
    * @dev Token transferability stored in settings initialization cannot be updated
    * @param fundsRecipient Global funds recipient
    * @param royaltyBPS ERC2981 compatible royalty basis points
    */
    function updateSettings(address payable fundsRecipient, uint16 royaltyBPS) external {
        // Request payments edit access from database
        if (_database.canEditPayments(address(this), _msgSenderERC721A()) == false) {  
            revert No_Settings_Access();
        }              
        // Check royaltyBPS for acceptable value
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

    /**
    * @notice Simple override for `OwnableUpgradeable` interface
    * @return ownerAddress Owner of contract
    */
    function owner() public view override(OwnableUpgradeable, IERC721Press) returns (address ownerAddress) {
        return super.owner();
    }    

    /**
    * @notice ContractURI getter
    * @dev Requests contractURI from database
    * @return uri ContractURI string
    */
    function contractURI() external view returns (string memory uri) {
        return IERC721PressDatabase(_database).contractURI();
    }    

    /**
    * @notice TokenURI getter
    * @dev Requests tokenURI from database
    * @param tokenId Id of token to request tokenURI for
    * @return uri TokenURI string 
    */
    function tokenURI(uint256 tokenId) public view override(ERC721AUpgradeable, IERC721Press) returns (string memory uri) {
        /// Reverts if requested tokenId does not exist
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }

        return IERC721PressDatabase(_database).tokenURI(tokenId);
    }

    /**
    * @notice Getter for database contract address used by Press
    * @return databaseAddress Database contract used by Press
    */
    function getDatabase() public view returns (IERC721PressDatabase databaseAddress) {
        return _database;
    }    

    /**
    * @notice Getter for Press settings
    * @return pressSettings Current settings for Press
    */    
    function getSettings() public view returns (IERC721Press.Settings memory pressSettings) {
        return IERC721Press.Settings({
            fundsRecipient: _settings.fundsRecipient,
            royaltyBPS: _settings.royaltyBPS,
            transferable: _settings.transferable
        });
    }     

    /**
    * @notice Getter for Press tokens' transferability status
    * @dev True => tokens are non-transferable. False => tokens are transferable
    * @return soulbound Transferability status of tokens minted from this Press
    */        
    function isSoulbound() external view returns (bool soulbound) {
        if (_settings.transferable == true) {
            return false;
        } else {
            return true;
        }
    }    

    /**
    * @notice Getter for last minted token id (gets next token id and subtracts 1)
    * @dev Also works as a "totalMinted" lookup
    * @return tokenId tokenId
    */
    function lastMintedTokenId() public view returns (uint256 tokenId) {
        return _nextTokenId() - 1;
    }            

    /**
    * @inheritdoc IERC165Upgradeable
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721AUpgradeable, IERC721Press)
        returns (bool interfaceSupported)
    {
        return super.supportsInterface(interfaceId) || type(IOwnableUpgradeable).interfaceId == interfaceId
            || type(IERC2981Upgradeable).interfaceId == interfaceId || type(IERC721Press).interfaceId == interfaceId
            || interfaceId == type(IERC5192).interfaceId;                    
    }    

    /**
    * @notice Getter that returns true if tokenId has been minted and not burned
    * @return existence true/false bool 
    */
    function exists(uint256 tokenId) external view returns (bool existence) {
        return _exists(tokenId);   
    }   

    /**
    * @notice Getter that returns tokenId transferability status
    * @dev True => token is non-transferable. False => token is transferable
    * @return transferable true/false bool 
    */
    function locked(uint256 tokenId) external virtual override(IERC5192) view returns (bool transferable) {
        if (_settings.transferable == true) {
            return false;
        } else {
            return true;
        }
    }         

    /**
    * @dev Getter for ERC2981 compatible token royalty information
    * @notice Returns zero values if Press fundsRecipient == address(9)
    * @param _tokenId The NFT asset queried for royalty information
    * @param _salePrice The sale price of the NFT asset specified by _tokenId
    * @return receiver Address of royalty recipient
    * @return royaltyAmount Royalty amount in wei to send to receiver
    */
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

    /**
    * @notice Getter that returns number of tokens minted by a given address
    * @return numMinted Number of tokens minted by address
    */    
    function mintedPerAddress(address minterAddress) external view returns (uint256 numMinted) {
        return _numberMinted(minterAddress);
    }        
    
    //////////////////////////////
    // INTERNAL
    //////////////////////////////     

    /**
    * @notice Start tokenId for minting (1 => 100 vs 0 => 99)
    * @return tokenId tokenId to start minting from
    */        
    function _startTokenId() internal pure override returns (uint256 tokenId) {
        return 1;
    }    

    /**
    * @dev Can only be called by contract owner
    * @param newImplementation proposed new upgrade implementation
    */         
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}    

    ////////////////////////////////////////////////////////////
    // NON-TRANSFERABLE TOKEN IMPLEMENTATION (EIP-5192)
    ////////////////////////////////////////////////////////////

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }    

    /**
    * @dev Overwritten to enable token transferability check
    */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }
    }        

    /**
    * @dev Overwritten to enable token transferability check
    */
    function approve(address approved, uint256 tokenId) public payable override {
        super.approve(approved, tokenId);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        if (_settings.transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }            
}