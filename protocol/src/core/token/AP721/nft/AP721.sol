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

import {AP721StorageV1} from "./storage/AP721StorageV1.sol";
import {IAP721} from "../interfaces/IAP721.sol";
import {IAP721Database} from "../interfaces/IAP721Database.sol";

import {IOwnableUpgradeable} from "../../../utils/ownable/single/IOwnableUpgradeable.sol";
import {OwnableUpgradeable} from "../../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../../utils/Version.sol";
import {FundsReceiver} from "../../../utils/FundsReceiver.sol";
import {TransferUtils} from "../../../utils/TransferUtils.sol";
import {IERC5192} from "../interfaces/IERC5192.sol";


/// TODO: make sure that burn calls dont need additional `exists` checks


/**
 * @title AP721
 * @notice Serves as a mirror for a corresponding row in an AP721Database impl
 * @dev The stored database impl is the only contract that has write access to this contract
 * @dev Uses EIP-5192 for (optional) non-transferrable token impl
 * @author Max Bochman
 * @author Salief Lewis
 */
contract AP721 is
    ERC721AUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    IAP721,
    OwnableUpgradeable,
    Version(1),
    AP721StorageV1,
    FundsReceiver,
    IERC5192
{

    ////////////////////////////////////////////////////////////
    // MODIFIERS 
    ////////////////////////////////////////////////////////////    

    /**
     * @notice Checks if database is msg.sender
     */
    modifier onlyDatabase() {
        // TODO: Can potentially use direct msg.sender here since this function will only be triggered
        //      by the database itself. The database itself can use _msgSender to allow for txn relaying
        //      but I believe this is unncessary at the AP721.sol level. Using msg.sender would save 200 gas per txn
        address sender = _msgSenderERC721A();
        if (sender != _database) {
            revert Msg_Sender_Not_Database();
        }

        _;
    }     

    ////////////////////////////////////////////////////////////
    // INITIALIZER 
    ////////////////////////////////////////////////////////////

    /**
    * @notice Initializes a new, creator-owned proxy of AP721.sol
    * @dev Database implementation + token transferrability cannot be adjusted after initialization
    * @dev `initializerERC721A` for ERC721AUpgradeable
    *      `initializer` for OwnableUpgradeable
    * @param initialOwner User that owns the contract upon deployment
    * @param database Database implementation address
    * @param init Data to use for init 
    */  
    function initialize(
        address initialOwner,
        address database,
        bytes memory init
    ) external nonReentrant initializerERC721A initializer {
        // Decode init data
        (
            string memory name,
            string memory symbol
        ) = abi.decode(init, (string, string));
        // Initialize ERC721A
        __ERC721A_init(name, symbol);
        // Initialize reentrancy guard
        __ReentrancyGuard_init();
        // Initialize owner for Ownable
        __Ownable_init(initialOwner);
        // Initialize UUPS
        __UUPSUpgradeable_init();                     
        // Set database
        _database = database;      
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    ////////////////////////////////////////////////////////////    

    //////////////////////////////
    // EXTERNAL
    ////////////////////////////// 

    /**
    * @notice User mint function
    * @dev Tokens can only be minted by calling `store` in database
    * @dev This batches in size of 8 as recommended by Chiru Labs
    * @param recipient Address to mint NFTs to
    * @param quantity Number of NFTs to mint
    */
    function mint(address recipient, uint256 quantity) onlyDatabase external {
        uint256 firstMintedTokenId = nextMintedTokenId();
        _mintNFTs(recipient, quantity);
        // Emit locked events if contract's tokens were initialized as non-transferable
        if (!IAP721Database(_database).getTransferable(address(this))) {
            for (uint256 i; i < quantity; ++i) {
                emit Locked(firstMintedTokenId + i);
            }   
        }        
    }    

    /**
    * @notice User burn function for tokenId
    * @dev Tokens can only be burned by calling `remove` in database
    * @dev The `remove` call in deletes data stored in database for a given target AP721 + toekenId
    * @param tokenId TokenId to burn
    */    
    function burn(uint256 tokenId) onlyDatabase external {
        // ERC721A _burn approvalCheck set to false to let custom logic take precedence
        _burn(tokenId, false);
    }     

    /**
    * @notice User burnBatch function for tokenId
    * @dev Tokens can only be burned by calling `remove` in database
    * @dev The `remove` call in deletes data stored in database for a given target AP721 + toekenId
    * @param tokenIds TokenIds to burn
    */    
    function burnBatch(uint256[] memory tokenIds) onlyDatabase external {
        for (uint256 i; i < tokenIds.length; ++i) {    
            // ERC721A _burn approvalCheck set to false to let custom logic take precedence
            _burn(tokenIds[i], false);
        }
    }         

    //////////////////////////////
    // INTERNAL
    ////////////////////////////// 

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
    function owner() public view override(OwnableUpgradeable, IAP721) returns (address ownerAddress) {
        return super.owner();
    }     

    /**
    * @notice ContractURI getter
    * @dev Requests contractURI from database
    * @return uri ContractURI string
    */
    function contractURI() public view returns (string memory uri) {
        return IAP721Database(_database).contractURI();
    }


    /**
    * @notice TokenURI getter
    * @dev Requests tokenURI from database
    * @param tokenId Id of token to request tokenURI for
    * @return uri TokenURI string 
    */
    function tokenURI(uint256 tokenId) public view override(ERC721AUpgradeable, IAP721) returns (string memory uri) {
        /// Reverts if requested tokenId does not exist
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }        
        return IAP721Database(_database).tokenURI(tokenId);
    }

    /**
    * @notice Getter for database contract address used by Press
    * @return databaseAddress Database contract used by Press
    */
    function getDatabase() external view returns (address databaseAddress) {
        return _database;
    }    

    /**
    * @notice Getter for next tokenId to be minted
    * @return tokenId tokenId
    */
    function nextMintedTokenId() public view returns (uint256 tokenId) {
        return _nextTokenId();
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
    * @notice Getter for AP721 tokens' transferability status
    * @dev True => tokens are non-transferable. False => tokens are transferable
    */  
    function locked(uint256 tokenId) external view returns (bool) {
        if (!IAP721Database(_database).getTransferable(address(this))) {
            return true;
        } else {
            return false;
        }
    }    

    /**
    * @notice Getter that returns true if tokenId has been minted and not burned
    * @return existence true/false bool 
    */
    function exists(uint256 tokenId) external view returns (bool existence) {
        return _exists(tokenId);   
    }       

    /**
    * @notice Getter that returns number of tokens minted by a given address
    * @return numMinted Number of tokens minted by address
    */    
    function mintedPerAddress(address minterAddress) external view returns (uint256 numMinted) {
        return _numberMinted(minterAddress);
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
        override(IERC2981Upgradeable, IAP721)
        returns (address receiver, uint256 royaltyAmount)
    {
        // Get AP721 settings from database
        (IAP721Database.Settings memory settings) = IAP721Database(_database).getSettings(address(this));   
        // Return no royalty value or recipient if fundsRecipient is zero value
        if (settings.ap721Config.fundsRecipient == address(0)) {
            return (address(0), 0);
        }             
        // If royaltyBPS > 100%, return royalty amount as the full _salePrice. Else return _salePrice * roylatyBPS / 10,000 
        if (settings.ap721Config.royaltyBPS > 100_000) {
            return (settings.ap721Config.fundsRecipient, _salePrice);
        } else {
            return (settings.ap721Config.fundsRecipient, (_salePrice * settings.ap721Config.royaltyBPS) / 10_000);
        }  
    }            

    /**
    * @inheritdoc IERC165Upgradeable
    */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721AUpgradeable, IAP721)
        returns (bool interfaceSupported)
    {
        return super.supportsInterface(interfaceId) || type(IOwnableUpgradeable).interfaceId == interfaceId
            || type(IERC2981Upgradeable).interfaceId == interfaceId || type(IAP721).interfaceId == interfaceId
            || interfaceId == type(IERC5192).interfaceId;                    
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
    * @dev Can only be upgraded to a supported impl
    * @param newImplementation proposed new upgrade implementation
    */         
    function _authorizeUpgrade(address newImplementation) internal override onlyDatabase {

        // NOTE: Currently set to be no-op

        // TODO: Determine if user should be able to upgrade AP721 through directly from contract
        //      or through database instead

        // if (_database.supportedImplementations(address(this), newImplementation) != 1) {
        //     revert Implementation_Not_Supported();
        // }
    }              

    ////////////////////////////////////////////////////////////
    // NON-TRANSFERABLE TOKEN IMPLEMENTATION (EIP-5192)
    ////////////////////////////////////////////////////////////

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
        if (!IAP721Database(_database).getTransferable(address(this))) {
            revert Non_Transferrable_Token();
        }
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
        if (!IAP721Database(_database).getTransferable(address(this))) {
            revert Non_Transferrable_Token();
        }
    }    

    /**
    * @dev Overwritten to enable token transferability check
    */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
        if (!IAP721Database(_database).getTransferable(address(this))) {
            revert Non_Transferrable_Token();
        }
    }        

    /**
    * @dev Overwritten to enable token transferability check
    */
    function approve(address approved, uint256 tokenId) public payable override {
        super.approve(approved, tokenId);
        if (!IAP721Database(_database).getTransferable(address(this))) {
            revert Non_Transferrable_Token();
        }        
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        if (!IAP721Database(_database).getTransferable(address(this))) {
            revert Non_Transferrable_Token();
        }        
    }                
}