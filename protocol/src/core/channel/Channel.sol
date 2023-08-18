// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */
import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";

import {IChannel} from "./interfaces/IChannel.sol";
import {IChannelTypesV1} from "./types/IChannelTypesV1.sol";
import {ChannelStorageV1} from "./storage/ChannelStorageV1.sol";
import {ILogic} from "./logic/ILogic.sol";
import {IRenderer} from "./renderer/IRenderer.sol";

import "sstore2/SSTORE2.sol";

/**
 * @title Channel
 */
contract Channel is
    ERC1155Upgradeable,
    IChannelTypesV1,
    IChannel,
    ChannelStorageV1,
    Version(1),
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{

    ////////////////////////////////////////////////////////////
    // INITIALIZER 
    ////////////////////////////////////////////////////////////

    /**
    * @notice Initializes a new, creator-owned proxy of Channel.sol
    */
    function initialize(
        string memory channelName, 
        address initialOwner,
        address riverImpl,
        address feeRouterImpl,
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
        river = riverImpl;
        feeRouter = feeRouterImpl;
        name = channelName;
        // symbol = contractSymbol;

        // Set channel storage
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
    // CHANNEL LEVEL
    //////////////////////////////       

    function storeChannelData(address sender, bytes memory data) external payable returns (address) {
        if (msg.sender != river) revert Sender_Not_River();        
        /* 
            Could put logic check here for sender
        */        
        (bytes memory dataToStore) = abi.decode(data, (bytes));
        channelData = SSTORE2.write(dataToStore);
        return channelData;
    }    

    function overwriteChannelData(address sender, bytes memory data) external returns (address) {
        if (msg.sender != river) revert Sender_Not_River();        
        /* 
            Could put logic check here for sender
        */        
        (bytes memory dataToStore) = abi.decode(data, (bytes));
        channelData = SSTORE2.write(dataToStore);
        return channelData;
    }      

    function removeChannelData(address sender, bytes memory data) external {
        if (msg.sender != river) revert Sender_Not_River();        
        /* 
            Could put logic check here for sender
        */        
        (bytes memory dataToStore) = abi.decode(data, (bytes));
        delete channelData;
    }        

    //////////////////////////////
    // TOKEN LEVEL
    //////////////////////////////           

    // TODO: confirm in tests that _mintBatch triggers a transfer single event when tokenIds array only has one element
    function storeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory) {
        if (msg.sender != river) revert Sender_Not_River();        
        (bytes[] memory tokens) = abi.decode(data, (bytes[]));
        // Initialize memory variables
        uint256 quantity = tokens.length;
        uint256[] memory tokenIds = new uint256[](quantity);                
        address[] memory pointers = new address[](quantity);        
        /* 
            Could put logic check here for sender + quantity 
        */
        for (uint256 i; i < quantity; ++i) {            
            tokenIds[i] = settings.counter;            
            pointers[i]  = tokenData[settings.counter] = SSTORE2.write(tokens[i]);    
            ++settings.counter;
        }
        _mintBatch(sender, tokenIds, _generateArrayOfOnes(quantity), new bytes(0));
        return (tokenIds, pointers);
    }

    function overwriteTokenData(address sender, bytes memory data) external returns (uint256[] memory, address[] memory) {
        if (msg.sender != river) revert Sender_Not_River();
        (uint256[] memory tokenIds, bytes[] memory datas) = abi.decode(data, (uint256[], bytes[]));
        if (tokenIds.length != datas.length) revert Input_Length_Mistmatch();
        // Initialize memory variables
        uint256 quantity = tokenIds.length;
        address[] memory pointers = new address[](quantity);        
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
    function removeTokenData(address sender, bytes memory data) external returns (uint256[] memory) {
        if (msg.sender != river) revert Sender_Not_River();
        (uint256[] memory tokenIds) = abi.decode(data, (uint256[]));
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
}