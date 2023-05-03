// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155PressContractLogic} from "../../../core/interfaces/IERC1155PressContractLogic.sol";
import {IERC1155Press} from "../../../core/interfaces/IERC1155Press.sol";

/**
* @title ERC1155EditionContractLogic
* @notice Edition contract level logic impl for AssemblyPress ERC1155 architecture
*
* @author Max Bochman
* @author Salief Lewis
*/
contract ERC1155EditionContractLogic is IERC1155PressContractLogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @dev 0 = Not initialized, 1 = Initialized
    struct ContractConfig {
        uint256 mintNewPrice;
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
    /// @notice Role value is not available 
    error Invalid_Role();
    /// @notice Cannot check results for given mintNew params
    error Invalid_MintNew_Inputs();    
    /// @notice Array input lengths don't match for access control updates
    error Invalid_Input_Length();    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when mintNew price updated
    /// @param targetPress Press that updated logic file
    /// @param mintNewPrice mintNew price for contract
    event MintNewPriceUpdated(
        address indexed targetPress,
        uint256 mintNewPrice
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
    uint16 public constant NO_ACCESS = 0;
    uint16 public constant MINTER = 1;
    uint16 public constant ADMIN = 2;

    /// @notice Press -> wallet -> uint256 access role
    mapping(address => mapping(address => uint16)) public accessInfo;         

    /// @notice Press -> {mintNewPrice, initialized}
    mapping(address => ContractConfig) public contractInfo;

    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 
    
    /// @notice Checks if target Press has been initialized
    modifier requireInitialized(address targetPress) {

        if (contractInfo[targetPress].initialized == 0) {
            revert Press_Not_Initialized();
        }

        _;
    }           

    /// @notice Checks if msg.sender has admin level privileges for given Press contract
    modifier requireSenderAdmin(address target) {

        if (msg.sender != target && accessInfo[target][msg.sender] != ADMIN) { 
            revert Not_Admin();
        }

        _;
    }          

    // ||||||||||||||||||||||||||||||||
    // ||| ACCESS CONTROL CHECKS ||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice checks mint access for a given mintQuantity + mintCaller
    /// @param targetPress press contract to check access for
    /// @param mintCaller address of mintCaller to check access for
    /// @param recipients recipients to check access for
    /// @param quantity quantity to check access for    
    function canMintNew(
        address targetPress, 
        address mintCaller,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if mintQuantity + mintCaller are valid inputs
        if (quantity == 0 || mintCaller == address(0)) {
            return false;
        }

        // check is any of the recipients are address(0)
        for (uint256 i; i < recipients.length; ++i) {
            if (recipients[i] == address(0)) {
                return false;
            }
        }        

        // check if mint caller has minting access for given mint quantity for given targetPress
        if (accessInfo[targetPress][mintCaller] < MINTER) {
            return false;
        }
        
        return true;
    }            

    /// @notice checks transfer access for a given transfer caller
    /// @param targetPress press contract to check access for
    /// @param transferCaller address of transferCaller to check access for
    function canSetOwner(
        address targetPress, 
        address transferCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if transferCaller caller has transfer access for given target Press
        if (accessInfo[targetPress][transferCaller] != ADMIN) {
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
        if (accessInfo[targetPress][upgradeCaller] != ADMIN) {
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
        if (contractInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }          

    /// @notice Checks mint price for provided combination
    /// @param targetPress press contract to check
    /// @param mintCaller address of mintCaller to check
    /// @param recipients recipients to check
    /// @param quantity quantity to check
    function mintNewPrice(
        address targetPress, 
        address mintCaller,
        address[] memory recipients,
        uint256 quantity
    ) external view requireInitialized(targetPress) returns (uint256) {
        // return mintNewPrice for targetPress
        return contractInfo[targetPress].mintNewPrice * quantity;
    }       

    // ||||||||||||||||||||||||||||||||
    // ||| LOGIC SETUP FUNCTIONS ||||||
    // ||||||||||||||||||||||||||||||||          

    /// @notice Default logic initializer for a given Press
    /// @notice admin cannot be set to the zero address
    /// @dev updates mappings for msg.sender, so no need to add access control to this function
    /// @param logicInit data to init with
    function initializeWithData(bytes memory logicInit) external {
        // data format: adminInit, mintPriceInit
        (address adminInit, uint256 mintNewPriceInit) = abi.decode(logicInit, (address, uint256));

        // check if admin set to the zero address
        if (adminInit == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // set initial admin in accessInfo mapping
        accessInfo[msg.sender][adminInit] = ADMIN;

        // update mutable values in contractInfo mapping
        contractInfo[msg.sender].mintNewPrice = mintNewPriceInit;

        // update immutable values in mintInfo mapping
        contractInfo[msg.sender].initialized = 1;

        emit MintNewPriceUpdated({
            targetPress: msg.sender,
            mintNewPrice: mintNewPriceInit
        });
    }       

    /// @notice Update access control
    /// @param targetPress target Press to update access control for
    /// @param receivers addresses to give roles to
    /// @param roles roles to give receiver addresses
    function setAccessControl(
        address targetPress,
        address[] memory receivers,
        uint16[] memory roles
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

    /// @notice Update mintNewPrie
    /// @param targetPress target for contract to update minting logic for
    /// @param newPrice new mintNewPrice 
    function updateMintNewPrice(
        address targetPress,
        uint256 newPrice
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // update mintNewPrice for target Press
        contractInfo[targetPress].mintNewPrice = newPrice;

        emit MintNewPriceUpdated({
            targetPress: msg.sender,
            mintNewPrice: newPrice
        });
    }           
}