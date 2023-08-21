// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";
import {FundsReceiver} from "../../utils/FundsReceiver.sol";

import {IPress} from "./interfaces/IPress.sol";
import {IPressTypesV1} from "./types/IPressTypesV1.sol";
import {PressStorageV1} from "./storage/PressStorageV1.sol";
import {ILogic} from "./logic/ILogic.sol";
import {IRenderer} from "./renderer/IRenderer.sol";
import {FeeManager} from "./fees/FeeManager.sol";
import {TransferUtils} from "../../utils/TransferUtils.sol";

import "sstore2/SSTORE2.sol";

// TODO: update the erc1155upgradeable version to the most recent OZ release. compiler there should be 0.8.20 if latest
//      and then update how non-transferability functionality is being added

/**
 * @title Press
 */
contract Press is
    ERC1155Upgradeable,
    IPressTypesV1,
    IPress,
    PressStorageV1,
    FeeManager,
    Version(1),
    FundsReceiver,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{

    constructor(address _feeRecipient, uint256 _fee) FeeManager(_feeRecipient, _fee) {}

    ////////////////////////////////////////////////////////////
    // INITIALIZER 
    ////////////////////////////////////////////////////////////

    /**
    * @notice Initializes a new, creator-owned proxy of Press.sol
    */
    function initialize(
        string memory pressName, 
        address initialOwner,
        address routerAddr,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit,
        AdvancedSettings memory advancedSettings
    ) external nonReentrant initializer {
        // We are not initalizing the OZ 1155 implementation
        // to save contract storage space and runtime
        // since the only thing affected here is the uri.
        // __ERC1155_init("");

        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable 
        __Ownable_init(initialOwner);
        // Setup UUPS
        __UUPSUpgradeable_init();   

        // Set things
        router = routerAddr;
        name = pressName;
        // symbol = contractSymbol;

        // Set press storage
        ++settings.counter; // this acts as an initialization check since will be 0 before init
        settings.logic = logic;
        settings.renderer = renderer;
        settings.advancedSettings = advancedSettings;
        
        // Initialize logic + renderer
        ILogic(logic).initializeWithData(logicInit);
        IRenderer(renderer).initializeWithData(rendererInit);
    }

    ////////////////////////////////////////////////////////////
    // DATA STORAGE
    ////////////////////////////////////////////////////////////      

    //////////////////////////////
    // PRESS LEVEL
    //////////////////////////////

    function updatePressData(address sender, bytes memory data) external payable returns (address) {        
        if (msg.sender != router) revert Sender_Not_Router();        
        /* 
            Could put logic check here for sender
        */        
        // Hardcoded `1` value since this function only updates 1 storage slot
        _handleFees(1);        
        (bytes memory dataToStore) = abi.decode(data, (bytes));        
        if (dataToStore.length == 0) {
            delete pressData;
            return pressData;
        } else {
            /* 
                Could put fee logic here, for when people are storing data
                Could even check if press data is zero or not 
                Otherwise maybe best to make this function non payable
            */      
            pressData = SSTORE2.write(dataToStore);
            return pressData;
        }
    }    

    //////////////////////////////
    // TOKEN LEVEL
    //////////////////////////////           

    // TODO: confirm in tests that _mintBatch triggers a transfer single event when tokenIds array only has one element
    function storeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory) {
        if (msg.sender != router) revert Sender_Not_Router();        
        (bytes[] memory tokens) = abi.decode(data, (bytes[]));
        // Initialize memory variables
        uint256 quantity = tokens.length;
        uint256[] memory tokenIds = new uint256[](quantity);                
        address[] memory pointers = new address[](quantity);        
        /* 
            Could put logic check here for sender + quantity 
        */
        _handleFees(quantity);             
        for (uint256 i; i < quantity; ++i) {            
            tokenIds[i] = settings.counter;            
            pointers[i]  = tokenData[settings.counter] = SSTORE2.write(tokens[i]);    
            ++settings.counter;
        }
        _mintBatch(sender, tokenIds, _generateArrayOfOnes(quantity), new bytes(0));
        return (tokenIds, pointers);
    }

    function overwriteTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory) {
        if (msg.sender != router) revert Sender_Not_Router();
        (uint256[] memory tokenIds, bytes[] memory datas) = abi.decode(data, (uint256[], bytes[]));
        if (tokenIds.length != datas.length) revert Input_Length_Mismatch();
        // Initialize memory variables
        uint256 quantity = tokenIds.length;
        address[] memory pointers = new address[](quantity);        
        _handleFees(quantity);                      
        for (uint256 i; i < quantity; ++i) {            
            /* 
                Could put logic check here for tokenId specific overwrite access
            */
            pointers[i]  = tokenData[tokenIds[i]] = SSTORE2.write(datas[i]);    
        }
        return (tokenIds, pointers);
    }    

    // TODO: consider adding in ability to decode tokenId burn quantities as well, unique to 1155
    // TODO: confirm in tests that _burnBatch triggers a transfer single event when tokenIds array only has one element
    function removeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory) {
        if (msg.sender != router) revert Sender_Not_Router();
        (uint256[] memory tokenIds) = abi.decode(data, (uint256[]));        
        _handleFees(tokenIds.length);                     
        for (uint256 i; i < tokenIds.length; ++i) {            
            /* 
                Could put logic check here for tokenId specific remove access
            */
            delete tokenData[tokenIds[i]];
        }
        _burnBatch(sender, tokenIds, _generateArrayOfOnes(tokenIds.length));        
        return tokenIds;
    }      

    ////////////////////////////////////////////////////////////
    // COLLECT
    ////////////////////////////////////////////////////////////    
    
    /*
        TODO:
        Confirm that we dont need to include an _exists(tokenId) check
    */

    //////////////////////////////
    // EXTERNAL
    //////////////////////////////           

    function collect(address recipient, uint256 tokenId, uint256 quantity) external payable nonReentrant {
        // Check that token type can be collected
        if (!settings.advancedSettings.fungible) revert Non_Fungible_Token();
        // Cache msg.sender
        address sender = msg.sender;
        // Get collect access and price from logic contract. Will revert if no access or msg.value is incorrect
        uint256 price = _getAccessAndPrice(sender, recipient, tokenId, quantity);
        // Process mint
        _mint(recipient, tokenId, quantity, new bytes(0));
        // Process funds redirect to override address if necesssary
        _handleFundsRecipientOverride(tokenId, price);
        // Emit Collected event
        emit Collected(sender, recipient, tokenId, quantity, price);
    }

    function collectBatch(address recipient, uint256[] memory tokenIds, uint256[] memory quantities) external payable nonReentrant {
        // Check that token type can be collected
        if (!settings.advancedSettings.fungible) revert Non_Fungible_Token();
        // Cache msg.sender
        address sender = msg.sender;        
        // Check for input length
        if (tokenIds.length != quantities.length) revert Input_Length_Mismatch();
        // Process collect requests
        for (uint256 i; i < tokenIds.length; ++i) {
            // Get collect access and price from logic contract. Will revert if no access or msg.value is incorrect
            uint256 price = _getAccessAndPrice(sender, recipient, tokenIds[i], quantities[i]);
            // Process mint
            _mint(recipient, tokenIds[i], quantities[i], new bytes(0));
            // Process funds redirect to override address if necesssary
            _handleFundsRecipientOverride(tokenIds[i], price);
            // Emit Collected event
            emit Collected(sender, recipient, tokenIds[i], quantities[i], price);            
        }
    }    

    function withdraw() public payable {
        uint256 pressEthBalance = address(this).balance;
        if (!TransferUtils.safeSendETH(
            settings.advancedSettings.fundsRecipient, 
            pressEthBalance, 
            TransferUtils.FUNDS_SEND_NORMAL_GAS_LIMIT
        )) {
            revert ETHWithdrawFailed(settings.advancedSettings.fundsRecipient, pressEthBalance);
        }        
    }

    //////////////////////////////
    // INTERNAL
    //////////////////////////////               

    function _getAccessAndPrice(address sender, address recipient, uint256 tokenId, uint256 quantity) internal returns (uint256) {
        (bool access, uint256 price) = ILogic(settings.logic).collectRequest(sender, recipient, tokenId, quantity);
        if (!access) revert No_Collect_Access();
        if (msg.value != price) revert Incorrect_Msg_Value();
        return price;
    }

    // TODO: consider adding an event to this for funds tracking?
    function _handleFundsRecipientOverride(uint256 tokenId, uint256 price) internal {
        address recipientOverride = fundsRecipientOverrides[tokenId];
        if (recipientOverride != address(0)) {
            TransferUtils.safeSendETH(
                recipientOverride, 
                price, 
                TransferUtils.FUNDS_SEND_LOW_GAS_LIMIT
            );
        }
    }    

    ////////////////////////////////////////////////////////////
    // READS
    ////////////////////////////////////////////////////////////       

    function isTransferable(uint256 tokenId) external returns (bool) {
        return settings.advancedSettings.transferable;
    }

    ////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////  

    //////////////////////////////
    // SETTINGS
    //////////////////////////////         

    /**
     * @param newImplementation proposed new upgrade implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override {}    

    // /**
    //  * @notice Start tokenId for minting (1 => 100 vs 0 => 99)
    //  * @return tokenId tokenId to start minting from
    //  */
    // function _startTokenId() internal pure override returns (uint256 tokenId) {
    //     return 1;
    // }    

    //////////////////////////////
    // HELPERS
    //////////////////////////////     

    function _generateArrayOfOnes(uint256 quantity) internal pure returns (uint256[] memory) {
        uint256[] memory arrayOfOnes = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            arrayOfOnes[i] = 1;
        }
        return arrayOfOnes;
    } 

    //////////////////////////////
    // OVERRIDES
    //////////////////////////////         

    /**
     * @dev See {ERC1155Upgradeable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        if (!settings.advancedSettings.transferable) {
            if (from != address(0) && to != address(0)) revert Non_Transferable_Token();   
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data); // call original implementation
    }

/*
    // @dev See {ERC1155Upgradeable-_update}
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override virtual {
        // Revert if function call is not a mint or burn
        if (!settings.advancedSettings.transferable) {
            if (from != address(0) || to != address(0)) revert Non_Transferable_Token();   
        }
        super._update(from, to, ids, values); // Call the original implementation
    }    
*/    
}