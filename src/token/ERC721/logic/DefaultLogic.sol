// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";

/**
* @title ERC721Press
* @notice DefaultLogic for AssemblyPress architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract DefaultLogic is IERC721PressLogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    struct MintConfig {
        uint256 mintPrice;
        uint64 maxSupply;
        uint64 mintCapPerAddress;
        uint8 initialized;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice Cannot set address to the zero address
    error Cannot_Set_Zero_Address();
    /// @notice Address does not have admin role
    error Not_Admin();
    /// @notice Cannot check results for given mint params
    error Invalid_Mint_Config();
    /// @notice Protects maxSupply from breaking when swapping in new logic
    error Cannot_Set_MaxSupply_Below_TotalMinted();
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();
    /// @notice Role value is not available 
    error Invalid_Role();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when mint config updated
    /// @param press Press that initialized logic file
    /// @param mintPrice universal mint price for contract
    /// @param maxSupply Press maxSupply
    /// @param mintCapPerAddress Press mintCapPerAddress
    event MintConfigInitialized(
        address indexed press,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    );    

    /// @notice Event emitted when mint config updated
    /// @param press Press that initialized logic file
    /// @param mintPrice universal mint price for contract
    /// @param maxSupply Press maxSupply
    /// @param mintCapPerAddress Press mintCapPerAddress
    event MintConfigUpdated(
        address indexed sender,
        address indexed press,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    );

    /// @notice Event emitted when access role is granted to an address
    /// @param sender address that sent txn
    /// @param targetPress Press contract role is being issued for
    /// @param receiver address recieving role
    /// @param role role being given
    event RoleGranted(
        address indexed sender,
        address indexed targetPress,
        address indexed receiver,
        uint256 role
    );        

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // Public constants for access roles
    uint16 public constant ANYONE = 0;
    uint16 public constant MINTER = 1;
    uint16 public constant MANAGER = 2;
    uint16 public constant ADMIN = 3;    

    /// @notice Press -> wallet -> uint256 access role
    mapping(address => mapping(address => uint256)) public accessInfo;         

    /// @notice Press -> {mintPrice, initialized, maxSupply, mintCapPerAddress}
    mapping(address => MintConfig) public mintInfo;           

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (mintInfo[targetPress].initialized == 0) {
            revert Press_Not_Initialized();
        }

        _;
    }        

    /// @notice Checks if msg.sender has admin level privileges for given Press contract
    modifier requireSenderAdmin(address target) {

        if (
            msg.sender != target && accessInfo[target][msg.sender] < ADMIN
            && msg.sender != IERC721Press(target).owner()  
        ) { 
            revert Not_Admin();
        }

        _;
    }                

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CONTROL CHECKS ||||||
    // ||||||||||||||||||||||||||||||||   

    /// @notice checks update access for a given update caller
    /// @param targetPress press contract to check access for
    /// @param updateCaller address of updateCaller to check access for
    function canUpdateConfig(
        address targetPress, 
        address updateCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if update caller has update access for given target Press
        if (accessInfo[targetPress][updateCaller] < ADMIN) {            
            return false;
        }

        return true;
    }                  

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    function canMint(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if mintQuantity + mintCaller are valid inputs
        if (mintQuantity == 0 || mintCaller == address(0)) {
            return false;
        }

        // check if mint caller has minting access for given mint quantity for given targetPress
        if (accessInfo[targetPress][mintCaller] < MINTER) {
            return false;
        }
        
        // check to see if mint call will mint tokens over maxSupply
        if (maxSupplyCheck(targetPress, mintQuantity) != true) {
            return false;
        }

        // check to see if mintCaller will exceed per wallet mint cap
        if (
            IERC721Press(targetPress).numberMinted(mintCaller)
            + mintQuantity > mintInfo[targetPress].mintCapPerAddress   
        ) {
            return false;
        }

        return true;
    }              

    /// @notice checks metadata edit access for a given edit caller
    /// @param targetPress press contract to check access for
    /// @param editCaller address of editCaller to check access for
    function canEditMetadata(
        address targetPress, 
        address editCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if edit caller has metadata editing access for given target Press
        if (accessInfo[targetPress][editCaller] < MANAGER) {
            return false;
        }

        return true;
    }           

    /// @notice checks funds withdrawl access for a given withdrawal caller
    /// @param targetPress press contract to check access for
    /// @param withdrawCaller address of withdrawCaller to check access for
    function canWithdraw(
        address targetPress, 
        address withdrawCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if withdrawCaller caller has withdraw access for given target Press
        if (accessInfo[targetPress][withdrawCaller] < MANAGER) {            
            return false;
        }

        return true;
    }                   

    /// @notice checks upgrade access for a given upgrade caller
    /// @param targetPress press contract to check access for
    /// @param upgradeCaller address of upgradeCaller to check access for
    function canUpgrade(
        address targetPress, 
        address upgradeCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if upgradeCaller has upgrade access for given target Press
        if (accessInfo[targetPress][upgradeCaller] < ADMIN) {
            return false;
        }

        return true;
    }            

    /// @notice checks burun access for a given burn caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param burnCaller address of burnCaller to check access for
    function canBurn(
        address targetPress, 
        uint256 tokenId,
        address burnCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if burnCaller caller has burn access for given target Press
        if (burnCaller == ERC721Press(payable(targetPress)).ownerOf(tokenId)) {
            return true;
        }

        return false;
    }          

    /// @notice checks transfer access for a given transfer caller
    /// @param targetPress press contract to check access for
    /// @param transferCaller address of transferCaller to check access for
    function canTransfer(
        address targetPress, 
        address transferCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if transferCaller caller has transfer access for given target Press
        if (accessInfo[targetPress][transferCaller] < ADMIN) {
            return false;
        }

        return true;
    }      

    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks value of initialized variable in mintInfo mapping for target Press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {

        // return false if targetPress has not been initialized
        if (mintInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }       

    /// @notice checks mint access for a given mintQuantity x mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintQuantity mintQuantity to check access for 
    /// @param mintCaller address of mintCaller to check access for
    function totalMintPrice(
        address targetPress, 
        uint64 mintQuantity, 
        address mintCaller
    ) external view requireInitialized(targetPress) returns (uint256) {

        // check if mintQuantity + mintCaller are valid inputs
        if (mintQuantity == 0 || mintCaller == address(0)) {
            revert Invalid_Mint_Config();
        }

        return mintInfo[targetPress].mintPrice;
    }       

    /// @notice checks value of maxSupply variable in mintInfo mapping for msg.sender
    /// @dev reverts if msg.sender has not been initialized
    function maxSupply() external view requireInitialized(msg.sender) returns (uint64) {
        return mintInfo[msg.sender].maxSupply;
    }            

    /// @notice checks to see if mint call will mint tokens over maxSupply
    /// @dev reverts if msg.sender has not been initialized
    /// @dev returns false if will breach maxSupply, true if not
    function maxSupplyCheck(address targetPress, uint64 mintQuantity) 
        internal 
        view
        requireInitialized(msg.sender) 
        returns (bool) 
    {
        // check to see if mint call will mint tokens over maxSupply
        if (
            IERC721Press(targetPress).lastMintedTokenId() + mintQuantity
            < mintInfo[targetPress].maxSupply
        ) {
            return false;
        }      

        return true;
    }           

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
    // ||||||||||||||||||||||||||||||||
    
    function updateLogicWithData(address targetPress, bytes memory initData) public {}              

    /// @notice Default logic initializer for a given Press
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        // data format: admin, mintPrice, maxSupply, mintCapPerAddress
        (
            address adminInit,
            uint256 mintPriceInit,
            uint64 maxSupplyInit,
            uint64 mintCapPerAddressInit
        ) = abi.decode(logicInit, (address, uint256, uint64, uint64));

        // check if admin set to the zero address
        if (adminInit == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // set initial admin in accessInfo mapping
        accessInfo[msg.sender][adminInit] = ADMIN;

        // check to see if maxSupply is lower than count of tokens aleady minted
        if (maxSupplyInit < IERC721Press(msg.sender).lastMintedTokenId()) {
            revert Cannot_Set_MaxSupply_Below_TotalMinted();
        }        

        // update mutable values in mintInfo mapping
        mintInfo[msg.sender].mintPrice = mintPriceInit;
        mintInfo[msg.sender].maxSupply = maxSupplyInit;
        mintInfo[msg.sender].mintCapPerAddress = mintCapPerAddressInit;

        // update immutable values in mintInfo mapping
        mintInfo[msg.sender].initialized = 1;

        emit MintConfigInitialized({
            press: msg.sender,
            mintPrice: mintPriceInit,
            maxSupply: maxSupplyInit,
            mintCapPerAddress: mintCapPerAddressInit
        });                   
    }   

    /// @notice Update access control
    /// @param targetPress target Press to update access control for
    /// @param receivers addresses to give roles to
    /// @param roles roles to give receiver addresses
    function setAccessControl(
        address targetPress,
        address[] memory receivers,
        uint256[] memory roles
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check for input mismatch between receivers & roles
        if (receivers.length != roles.length) {
            revert Invalid_Input_Length();
        }

        // initiate for loop for length of receivers array
        for (uint256 i; i < receivers.length; i++) {

            // cannot give address(0) a role
            if (receivers[i] == address(0)) {
                revert Cannot_Set_Zero_Address();
            }

            // check to see if role value is valid 
            if (roles[i] > ADMIN ) {
                revert Invalid_Role();
            }            

            // grant access role to designated receiever
            accessInfo[targetPress][receivers[i]] = roles[i];
            
            // emit new role as event
            emit RoleGranted({
                sender: msg.sender,
                targetPress: targetPress,
                receiver: receivers[i],
                role: roles[i]
            });
        }
    }        

    /// @notice Update minting logic
    /// @param targetPress target for contract to update minting logic for
    /// @param mintPrice mintPrice uint256
    /// @param maxSupply maxSupply uint64
    /// @param mintCapPerAddress mintCapPerAddress uint64
    /// @dev does not provide ability to edit initialized variable
    function updateMintConfig(
        address targetPress,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check to see if maxSupply is lower than count of tokens aleady minted
        if (maxSupply < IERC721Press(targetPress).lastMintedTokenId()) {
            revert Cannot_Set_MaxSupply_Below_TotalMinted();
        }

        // update MintConfig for target Press
        mintInfo[targetPress].mintPrice = mintPrice;
        mintInfo[targetPress].maxSupply = maxSupply;
        mintInfo[targetPress].mintCapPerAddress = mintCapPerAddress;

        emit MintConfigUpdated({
            sender: msg.sender,
            press: targetPress,
            mintPrice: mintPrice,
            maxSupply: maxSupply,
            mintCapPerAddress: mintCapPerAddress
        });
    }         
}
