// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/* PA */

import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
* @title ERC721Press
*
*/
contract AP721 is ReentrancyGuard {

    ////////////////////////////////////////////////////////////
    // MODIFIERS 
    ////////////////////////////////////////////////////////////    

    /**
     * @notice Checks if database is msg.sender
     */
    modifier onlyDatabase() {
        address sender = _msgSender();
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
    * @param name Contract name
    * @param symbol Contract symbol
    * @param initialOwner User that owns the contract upon deployment
    * @param database Database implementation address
    */  
    function initialize(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        address database
    ) external nonReentrant initializerERC721A initializer {
        // Initialize ERC721A
        __ERC721A_init(name, symbol);
        // Initialize reentrancy guard
        __ReentrancyGuard_init();
        // Initialize owner for Ownable
        __Ownable_init(initialOwner);
        // Initialize UUPS
        __UUPSUpgradeable_init();                     
        // Set dataase
        _database = database;      
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS 
    ////////////////////////////////////////////////////////////    

    //////////////////////////////
    // EXTERNAL
    ////////////////////////////// 

    /**
    * NOTE:
    * Transfer and upgrade are provided through inheriteed
    * Transfer access control managed by OwnableUpgradeable
    * Upgrade access control managed by `authorizeUpgrade` internal read function
    */

    function mint(uint256 quantity, address recipient) onlyDatabase external {

    }

    // tokens can only be burned through database
    function burn(uint256 tokenId) onlyDatabase external {

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

    function contractURI() external view returns (string memory) {

    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {

    }

    function getDatabase() external view returns (address) {

    }    

    function lastMintedTokenId() public view returns (uint256) {

    }        

    function totalSupply() external view returns (uint256) {

    }    

    function mintedPerAddress(address minterAddress) external view returns (uint256) {

    }        

    function locked(uint256 tokenId) external view returns (bool) {

    }    

    function exists(uint256 tokenId) external view returns (bool) {

    }        

    /**
    * @inheritdoc IERC165Upgradeable
    */
    function supportsInteface(bytes4 interfaceId) public view returns (bool) {

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

        (uint16 royaltyBPS) = _database.settingsInfo(address(this)).royaltyBPS;

        if (_database.settingsInfo(address(this)).royaltyBPS > 100_000) {
            return 100_000;
        } else {
            return royaltyBPS;
        }
        
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
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        if (_database.supportedImplementations(address(this), newImplementation) != 1) {
            revert Implementation_Not_Supported();
        }
    }              

    ////////////////////////////////////////////////////////////
    // NON-TRANSFERABLE TOKEN IMPLEMENTATION (EIP-5192)
    ////////////////////////////////////////////////////////////

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        super.safeTransferFrom(from, to, tokenId, data);
        if (_database.pressSettings(address(this)).transferable == false) {
            revert Non_Transferrable_Token();
        }
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        super.safeTransferFrom(from, to, tokenId);
        if (_database.pressSettings(address(this)).transferable == false) {
            revert Non_Transferrable_Token();
        }
    }    

    /**
    * @dev Overwritten to enable token transferability check
    */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        super.transferFrom(from, to, tokenId);
        if (_database.pressSettings(address(this)).transferable == false) {
            revert Non_Transferrable_Token();
        }
    }        

    /**
    * @dev Overwritten to enable token transferability check
    */
    function approve(address approved, uint256 tokenId) public payable override {
        super.approve(approved, tokenId);
        if (_database.pressSettings(address(this)).transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }

    /**
    * @dev Overwritten to enable token transferability check
    */
    function setApprovalForAll(address operator, bool approved) public override {
        super.setApprovalForAll(operator, approved);
        if (_database.pressSettings(address(this)).transferable == false) {
            revert Non_Transferrable_Token();
        }        
    }                
}