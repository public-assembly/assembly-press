// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155PressTokenLogic} from "../../../core/interfaces/IERC1155PressTokenLogic.sol";
import {IERC1155Press} from "../../../core/interfaces/IERC1155Press.sol";
import {ERC1155Press} from "../../../ERC1155Press.sol";

/**
* @title ERC1155EditionTokenLogic
* @notice Edition token level logic impl for AssemblyPress ERC1155 architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract ERC1155EditionTokenLogic is IERC1155PressTokenLogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev mintCapPerAddress: 0 = unlimited mint cap, 1 = mint cap of 1
    /// @dev initialized: 0 = Not initialized, 1 = Initialized
    struct MintConfig {
        uint256 startTime;
        uint256 mintExistingPrice;
        uint256 mintCapPerAddress;
        uint8 initialized;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Target Press -> tokenId has not been initialized
    error TokenId_Not_Initialized();
    /// @notice Cannot set address to the zero address
    error Cannot_Set_Zero_Address();
    /// @notice Address does not have admin role
    error Not_Admin();
    /// @notice Role value is not available 
    error Invalid_Role();
    /// @notice Cannot check results for given mintNew params
    error Invalid_MintNew_Inputs();    
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();    
    /// @notice Cant adjust time if minting has already started    
    error Minting_Already_Started();
    /// @notice No access to mint existing function
    error No_MintExisting_Access();
    /// @notice Cannot mint quantity as it will exceed wallet address mint cap
    error Mint_Will_Exceed_Cap();    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when mintExisting price updated
    /// @param targetPress Press that updated logic file
    /// @param startTime startTime for mintExisting function
    event StartTimeUpdated(
        address indexed targetPress,
        uint256 startTime
    );        

    /// @notice Event emitted when Press -> tokenId mintConfig updated
    /// @param targetPress Press config being set
    /// @param tokenId tokenId config to targeted
    /// @param startTime unix second value when mintExisting becomes open to public
    /// @param mintExistingPrice public mintExistingPrice 
    /// @param mintCapPerAddress max mint per wallet address
    event MintConfigUpdated(
        address indexed targetPress,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 mintExistingPrice,
        uint256 mintCapPerAddress
    );     

    /// @notice Event emitted when access role is granted to an address
    /// @param sender address that sent txn
    /// @param targetPress Press contract role is being issued for
    /// @param tokenId tokenId role is being issued to
    /// @param receiver address recieving role
    /// @param role role being given
    event RoleGranted(
        address indexed sender,
        address indexed targetPress,
        uint256 indexed tokenId, 
        address receiver,
        uint256 role
    );              

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    // Public constants for access roles
    uint16 public constant NO_ACCESS = 0;
    uint16 public constant MINTER = 1;
    uint16 public constant ADMIN = 2;

    /// @notice Press -> tokenId -> wallet -> uint256 access role
    mapping(address => mapping(uint256 => mapping(address => uint256))) public accessInfo;         

    /// @notice Press -> tokenId -> {startTime, mintExistingPrice, mintCapPerAddress initialized}
    mapping(address => mapping(uint256 => MintConfig)) public tokenInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 
    
    /// @notice Checks if target Press + tokenId has been initialized
    modifier requireInitialized(address targetPress, uint256 tokenId) {

        if (tokenInfo[targetPress][tokenId].initialized == 0) {
            revert TokenId_Not_Initialized();
        }

        _;
    }           

    /// @notice Checks if msg.sender has admin level privileges for given Press -> tokenid
    modifier requireSenderAdmin(address target, uint256 tokenId) {

        if (msg.sender != target && accessInfo[target][tokenId][msg.sender] != ADMIN) { 
            revert Not_Admin();
        }

        _;
    }          

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CONTROL CHECKS ||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice checks editMetadata access for given press -> tokenId -> msg caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param editCaller address of transferCaller to check access for
    function canEditMetadata(
        address targetPress, 
        uint256 tokenId,
        address editCaller
    ) external view requireInitialized(targetPress, tokenId) returns (bool) {

        // check if transferCaller caller has transfer access for given target Press + tokenId
        if (accessInfo[targetPress][tokenId][editCaller] != ADMIN) {
            return false;
        }

        return true;
    }          

    /// @notice checks updateConfig access for given press -> tokenId -> msg caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param updateCaller address of updateCaller to check access for
    function canUpdateConfig(
        address targetPress, 
        uint256 tokenId,
        address updateCaller
    ) external view requireInitialized(targetPress, tokenId) returns (bool) {

        // check if transferCaller caller has transfer access for given target Press + tokenId
        if (accessInfo[targetPress][tokenId][updateCaller] != ADMIN) {
            return false;
        }

        return true;
    }          

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintCaller address of mintCaller to check access for
    /// @param tokenId tokenId check access for
    /// @param recipients recipients to check access for
    /// @param quantity quantity to check access for    
    function canMintExisting(
        address targetPress, 
        address mintCaller,
        uint256 tokenId,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress, tokenId) returns (bool) {

        // check to see if startTime has passed yet
        if (block.timestamp < tokenInfo[targetPress][tokenId].startTime) {
            return false;
        }
        // chcek to see if mint will take user over their mint cap
        if (
            ERC1155Press(payable(targetPress)).numMinted(tokenId, mintCaller) + quantity 
            >  tokenInfo[targetPress][tokenId].mintCapPerAddress
        ) {
            return false;
        }
        
        // allow user to mint if none of the above are true
        return true;
    }            

    /// @notice checks withdraw access for given press -> tokenId -> msg caller
    /// @param targetPress press contract to check access for
    /// @param tokenId tokenId to check access for
    /// @param withdrawCaller address of withdrawCaller to check access for
    function canWithdraw(
        address targetPress, 
        uint256 tokenId,
        address withdrawCaller
    ) external view requireInitialized(targetPress, tokenId) returns (bool) {
        // anyone can call withdraw function at anytime
        return true;
    }   

    // ||||||||||||||||||||||||||||||||
    // ||| STATUS CHECKS ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice checks value of initialized variable in tokenInfo mapping for target Press + tokenId
    /// @param targetPress press contract to check initialization status
    /// @param tokenId tokenId to check initialization status
    function isInitialized(address targetPress, uint256 tokenId) external view returns (bool) {

        // return false if targetPress + tokenId has not been initialized
        if (tokenInfo[targetPress][tokenId].initialized == 0) {
            return false;
        }

        return true;
    }          

    /// @notice Checks mint price for provided combination
    /// @param targetPress press contract to check
    /// @param tokenId tokenId to check
    /// @param mintCaller address of mintCaller to check
    /// @param recipients recipients to check
    /// @param quantity quantity to check
    function mintExistingPrice(
        address targetPress, 
        uint256 tokenId,
        address mintCaller,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress, tokenId) returns (uint256) {
        // return mintExistingPrice for targetPress + tokenId
        return tokenInfo[targetPress][tokenId].mintExistingPrice * quantity;
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(uint256 tokenId, bytes memory logicInit) external {
        // data format: adminInit, startTimeInit, mintExistingPriceInit, mintCapPerAddressInit
        (
            address adminInit, 
            uint256 startTimeInit,
            uint256 mintExistingPriceInit
        ) = abi.decode(logicInit, (address, uint256, uint256));

        // check if admin set to the zero address
        if (adminInit == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Cache msg.sender
        address sender = msg.sender;

        // set initial admin in accessInfo mapping
        accessInfo[sender][tokenId][adminInit] = ADMIN;

        // update mutable values in tokenInfo mapping
        tokenInfo[sender][tokenId].startTime = startTimeInit;        
        tokenInfo[sender][tokenId].mintExistingPrice = mintExistingPriceInit;
        // if free mint, mintCapPerAddress automatically set to 1
        // if paid mint, mintCapPerAddress automically set to ~ unlimited
        if (mintExistingPriceInit == 0) {
            tokenInfo[sender][tokenId].mintCapPerAddress = 1;
        } else {
            tokenInfo[sender][tokenId].mintCapPerAddress = type(uint256).max;
        }
        
        // update immutable values in mintInfo mapping
        tokenInfo[sender][tokenId].initialized = 1;

        emit MintConfigUpdated({
            targetPress: sender,
            tokenId: tokenId,
            startTime: startTimeInit,
            mintExistingPrice: mintExistingPriceInit,
            mintCapPerAddress: tokenInfo[sender][tokenId].mintCapPerAddress
        });
    }       

    /// @notice Update access control
    /// @param targetPress target Press to update access control for
    /// @param tokenId target tokenId to update access control for    
    /// @param receivers addresses to give roles to
    /// @param roles roles to give receiver addresses
    function setAccessControl(
        address targetPress,
        uint256 tokenId,
        address[] memory receivers,
        uint256[] memory roles
    ) external requireInitialized(targetPress, tokenId) requireSenderAdmin(targetPress, tokenId) {

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
            accessInfo[targetPress][tokenId][receivers[i]] = roles[i];
            
            // emit new role as event
            emit RoleGranted({
                sender: msg.sender,
                targetPress: targetPress,
                tokenId: tokenId,
                receiver: receivers[i],
                role: roles[i]
            });
        }
    }     

    /// @notice Update updateStartTime
    /// @param targetPress target for contract to update start time for
    /// @param tokenId target tokenId to update start time for
    /// @param newStartTime new startTime
    function updateStartTime(
        address targetPress,
        uint256 tokenId,
        uint256 newStartTime
    ) external requireInitialized(targetPress, tokenId) requireSenderAdmin(targetPress, tokenId) {

        // Check if minting has already started for tokenId
        // Cannot edit if startTime is in the past
        if (block.timestamp > tokenInfo[targetPress][tokenId].startTime) {
            revert Minting_Already_Started();
        }

        // Update startTime for target Press + tokenId
        tokenInfo[targetPress][tokenId].startTime = newStartTime;

        emit MintConfigUpdated({
            targetPress: targetPress,
            tokenId: tokenId,
            startTime: newStartTime,
            mintExistingPrice: tokenInfo[targetPress][tokenId].mintExistingPrice,
            mintCapPerAddress: tokenInfo[targetPress][tokenId].mintCapPerAddress
        });
    }           
}