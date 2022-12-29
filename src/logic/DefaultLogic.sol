// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IPress} from "../interfaces/IPress.sol";
import {ILogic} from "../interfaces/ILogic.sol";

/**
 @notice DefaultLogic for AssemblyPress architecture
 @author Max Bochman
 */
contract DefaultLogic is ILogic {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Shared listing struct for minter + editor + admin
    struct AccessControl {
        address minter;
        address editor;
        address admin;
    }

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

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Press -> {minter, editor, admin}
    mapping(address => AccessControl) public accessInfo;     

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
            msg.sender != target && msg.sender != accessInfo[target].admin 
            && msg.sender != IPress(target).owner()  
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
            IPress(targetPress).lastMintedTokenId() + mintQuantity
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
        if (mintCaller != accessInfo[targetPress].minter) {
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
        if (editCaller != accessInfo[targetPress].editor) {
            revert NO_EDIT_ACCESS();
        }

        return true;
    }           

    /// @notice checks funds withdrawl access for a given wtihdrawal caller
    /// @param targetPress press contract to check access for
    /// @param withdrawCaller address of withdrawCaller to check access for
    function canWithdraw(
        address targetPress, 
        address withdrawCaller
    ) external view requireInitialized(targetPress) returns (bool) {

        // check if withdrawCaller caller has balance withdraw access for given target Press
        if (withdrawCaller != accessInfo[targetPress].admin) {
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

        // check if withdrawCaller caller has balance withdraw access for given target Press
        if (updateCaller != accessInfo[targetPress].admin) {
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
        if (upgradeCaller != accessInfo[targetPress].admin) {
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

        // check if burnCaller caller has balance burn access for given target Press
        if (burnCaller != accessInfo[targetPress].admin) {
            revert NO_BURN_ACCESS();
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
        // data format: minter, editor, admin, mintPrice, mintCapPerAddress
        (
            address minterInit, 
            address editorInit,
            address adminInit,
            uint256 mintPriceInit,
            uint64 maxSupplyInit,
            uint64 mintCapPerAddressInit
        ) = abi.decode(logicInit, (address, address, address, uint256, uint64, uint64));

        // check if minter, editor, or admin set to zero address
        if (minterInit == address(0) || editorInit == address(0) || adminInit == address(0)) {
            revert CANNOT_SET_ZERO_ADDRESS();
        }

        // update values in accessInfo mapping
        accessInfo[msg.sender].minter = minterInit;
        accessInfo[msg.sender].editor = editorInit;
        accessInfo[msg.sender].admin = adminInit;

        // check to see if maxSupply is lower than count of tokens aleady minted
        if (maxSupplyInit < IPress(msg.sender).lastMintedTokenId()) {
            revert CANNOT_SET_MAXSUPPLY_BELOW_TOTAL_MINTED();
        }        

        // update mutable values in mintInfo mapping
        mintInfo[msg.sender].mintPrice = mintPriceInit;
        mintInfo[msg.sender].maxSupply = maxSupplyInit;
        mintInfo[msg.sender].mintCapPerAddress = mintCapPerAddressInit;

        // update immutable values in mintInfo mapping
        mintInfo[msg.sender].initialized = 1;        
    }   

    /* POTENTIALLY ADD INDIVIDUAL UPDATE FUNCTIONS AS WELL? */
    /// @notice Update access control
    /// @param targetPress target press to update access control for
    /// @param minter minter address
    /// @param editor editor address
    /// @param admin admin address
    function updateAccessControl(
        address targetPress,
        address minter,
        address editor,
        address admin
    ) external requireInitialized(targetPress) requireSenderAdmin(targetPress) {

        // check if minter, editor, or admin set to zero address
        if (minter == address(0) || editor == address(0) || admin == address(0)) {
            revert CANNOT_SET_ZERO_ADDRESS();
        }

        // update access control for target press
        accessInfo[targetPress].minter = minter;
        accessInfo[targetPress].editor = editor;
        accessInfo[targetPress].admin = admin;
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
        if (maxSupply < IPress(targetPress).lastMintedTokenId()) {
            revert CANNOT_SET_MAXSUPPLY_BELOW_TOTAL_MINTED();
        }

        // update minting logic for target press
        mintInfo[targetPress].mintPrice = mintPrice;
        mintInfo[targetPress].maxSupply = maxSupply;
        mintInfo[targetPress].mintCapPerAddress = mintCapPerAddress;
    }         
}