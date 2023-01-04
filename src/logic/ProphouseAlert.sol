// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ILogic} from "../interfaces/ILogic.sol";

/**
 @notice DefaultLogic for AssemblyPress architecture
 @author Max Bochman
 */
contract ProphouseAlert is ILogic {

    // prop house stuff

    // struct ProposalDetails {
    //     string title;
    //     string description;
    // }

    // struct VoteDetails {
    //     uint256 proposal;
    //     string reason;
    // }
    
    // // track proposal submissions
    // mapping(uint256 => ProposalDetails) public proposalInfo;
    // uint256 public proposalCounter = 1;

    // // track vote + replies 
    // mapping(uint256 => VoteDetails) public voteInfo;
    // uint256 public voteCounter = 1;    

    // /// @notice Checks if target press has been initialized
    // modifier requireRoundExists(uint256 round) {

    //     if (mintInfo[targetPress].initialized == 0) {
    //         revert PRESS_NOT_INITIALIZED();
    //     }

    //     _;
    // }           
    
    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    struct MintingLogic {
        uint256 mintPrice;
        uint64 maxSupply; // max value = 18446744073709551615
        uint64 mintCapPerAddress; // max value = 18446744073709551615
        uint8 initialized;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    error PRESS_NOT_INITIALIZED();
    error Not_Admin();
    error INVALID_MINT_CONFIG();
    error NO_MINTING_ACCESS();
    error NO_WITHDRAW_ACCESS();
    error CANNOT_SET_ZERO_ADDRESS();
    error NO_EDIT_ACCESS();
    error CANNOT_SET_MAXSUPPLY_BELOW_TOTAL_MINTED();
    error NO_UPGRADE_ACCESS();
    error NO_UPDATE_ACCESS();
    error NO_BURN_ACCESS();
    error MAX_SUPPLY_HAS_BEEN_REACHED();
    error NO_TRANSFER_ACCESS();
    error INVALID_INPUT_LENGTH();
    error INVALID_ROLE();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when access role is granted to an address
    /// @param targetPress Press contract role is being issued for
    /// @param receiver address recieving role
    /// @param role role being given
    event RoleGranted(
        address indexed targetPress,
        address indexed receiver,
        uint256 indexed role
    );        

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // Public constants for access roles.
    // Allows for adding new types later easily compared to a enum.
    uint16 public constant NO_ACCESS = 0;
    uint16 public constant MINTER = 1;
    uint16 public constant MANAGER = 2;
    uint16 public constant ADMIN = 3;    

    /// @notice Press -> wallet -> uint256 access role
    mapping(address => mapping(address => uint256)) public accessInfo;         

    /// @notice Press -> {mintPrice, initialized, maxSupply, mintCapPerAddress}
    mapping(address => MintingLogic) public mintInfo;           

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if target press has been initialized
    modifier requireInitialized(address targetPress) {

        if (mintInfo[targetPress].initialized == 0) {
            revert PRESS_NOT_INITIALIZED();
        }

        _;
    }        

    /// @notice Checks if msg.sender has admin level privalages for given Press contract
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
    // ||| VIEW FUNCTIONS |||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice checks value of initialized variable in mintInfo mapping for target press
    /// @param targetPress press contract to check initialization status
    function isInitialized(address targetPress) external view returns (bool) {

        // return false if targetPress has not been initialized
        if (mintInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
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
        public 
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
            revert INVALID_MINT_CONFIG();
        }

        // check if mint caller has minting access for given mint quantity for given targetPress
        if (accessInfo[targetPress][mintCaller] < MINTER) {
            revert NO_MINTING_ACCESS();
        }
        
        // check to see if mint call will mint tokens over maxSupply
        maxSupplyCheck(targetPress, mintQuantity);        

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
            revert INVALID_MINT_CONFIG();
        }

        return mintInfo[targetPress].mintPrice;
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
            revert NO_EDIT_ACCESS();
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
            revert NO_WITHDRAW_ACCESS();
        }

        return true;
    }               

    /// @notice checks update access for a given update caller
    /// @param targetPress press contract to check access for
    /// @param updateCaller address of updateCaller to check access for
    function canUpdatePressConfig(
        address targetPress, 
        address updateCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if update caller has update access for given target Press
        if (accessInfo[targetPress][updateCaller] < ADMIN) {            
            revert NO_UPDATE_ACCESS();
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
            revert NO_UPGRADE_ACCESS();
        }

        return true;
    }            

    /// @notice checks burun access for a given burn caller
    /// @param targetPress press contract to check access for
    /// @param burnCaller address of burnCaller to check access for
    function canBurn(
        address targetPress, 
        address burnCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if burnCaller caller has burn access for given target Press
        if (accessInfo[targetPress][burnCaller] < ADMIN) {
            revert NO_BURN_ACCESS();
        }

        return true;
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
            revert NO_TRANSFER_ACCESS();
        }

        return true;
    }      

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL WRITE FUNCTIONS |||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @notice minter + editor + admin cannot be set to address(0)
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

        // check if admin set to zero address
        if (adminInit == address(0)) {
            revert CANNOT_SET_ZERO_ADDRESS();
        }

        // set initial admin in accessInfo mapping
        accessInfo[msg.sender][adminInit] = ADMIN;

        // check to see if maxSupply is lower than count of tokens aleady minted
        if (maxSupplyInit < IERC721Press(msg.sender).lastMintedTokenId()) {
            revert CANNOT_SET_MAXSUPPLY_BELOW_TOTAL_MINTED();
        }        

        // update mutable values in mintInfo mapping
        mintInfo[msg.sender].mintPrice = mintPriceInit;
        mintInfo[msg.sender].maxSupply = maxSupplyInit;
        mintInfo[msg.sender].mintCapPerAddress = mintCapPerAddressInit;

        // update immutable values in mintInfo mapping
        mintInfo[msg.sender].initialized = 1;        
    }   

    /// @notice Update access control
    /// @param targetPress target press to update access control for
    /// @param receivers addresses to give roles to
    /// @param roles roles to give receiver addresses
    function setAccessControl(
        address targetPress,
        address[] memory receivers,
        uint256[] memory roles
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check for input mismatch between receivers & roles
        if (receivers.length != roles.length) {
            revert INVALID_INPUT_LENGTH();
        }

        // initiate for loop for length of receivers array
        for (uint256 i; i < receivers.length; i++) {

            // cannot give address(0) a role
            if (receivers[i] == address(0)) {
                revert CANNOT_SET_ZERO_ADDRESS();
            }

            // check to see if role value is valid 
            if (roles[i] > ADMIN ) {
                revert INVALID_ROLE();
            }            

            // grant access role to designated receiever
            accessInfo[targetPress][receivers[i]] = roles[i];
            
            // emit new role as event
            emit RoleGranted({
                targetPress: targetPress,
                receiver: receivers[i],
                role: roles[i]
            });
        }
    }        

    /* POTENTIALLY ADD INDIVIDUAL UPDATE FUNCTIONS AS WELL? */
    /// @notice Update minting logic
    /// @param targetPress target for contract to update minting logic for
    /// @param mintPrice mintPrice uint256
    /// @param maxSupply maxSupply uint64
    /// @param mintCapPerAddress mintCapPerAddress uint64
    /// @dev does not provide ability to edit initialized variable
    function updateMintingLogic(
        address targetPress,
        uint256 mintPrice,
        uint64 maxSupply,
        uint64 mintCapPerAddress
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check to see if maxSupply is lower than count of tokens aleady minted
        if (maxSupply < IERC721Press(targetPress).lastMintedTokenId()) {
            revert CANNOT_SET_MAXSUPPLY_BELOW_TOTAL_MINTED();
        }

        // update minting logic for target press
        mintInfo[targetPress].mintPrice = mintPrice;
        mintInfo[targetPress].maxSupply = maxSupply;
        mintInfo[targetPress].mintCapPerAddress = mintCapPerAddress;
    }         
}