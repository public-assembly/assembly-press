// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "./utils/OwnableUpgradeable.sol";
import {Version} from "./utils/Version.sol";

import {IOwnableUpgradeable} from "./interfaces/IOwnableUpgradeable.sol";

import {ILogic} from "./interfaces/ILogic.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";

import {IERC1155Logic} from "./interfaces/IERC1155Logic.sol";
import {IContractLogic} from "./interfaces/IContractLogic.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC1155Press} from "./interfaces/IERC1155Press.sol";

/**
 * @title ERC1155Press
 * @notice Lightweight + opinionated ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    Version(1),
    ERC1155PressStorageV1,
    IERC1155Press
{
    /// @dev Max royalty basis points (BPS)
    uint16 constant MAX_ROYALTY_BPS = 50_00;

    /// @dev Max minting finders fee (BPS)
    uint16 constant MAX_FINDERS_FEE = 50_00;    

    // contract name + contract symbol
    string public contractName;
    string public contractSymbol;

    // custom counter since cant use ERC721A's
    /* start with 1? */
    /* change to startTokenId ? */
    uint256 internal _tokenCount = 0;

    /**
     * Initializer
     */
    ///  @param _name Contract name
    ///  @param _symbol Contract symbol
    ///  @param _initialOwner User that owns the contract upon deployment  
    ///  @param _contractLevelLogic Contract level logic contract to use for access control
    ///  @param _contractLevelLogicInit Contract level logic optional init data
    function initialize(
        string memory _name, 
        string memory _symbol, 
        address _initialOwner,
        address _contractLevelLogic,
        bytes memory _contractLevelLogicInit
    ) public initializer {
        /* we prob gonna never use this */
        // used to set uri for all token types by relying on id substitiion, e.g. https://token-cdn-domain/{id}.json
        __ERC1155_init("");

        // Setup reentrancy guard
        __ReentrancyGuard_init();

        // Set ownership to original sender of contract call
        __Ownable_init(_initialOwner);

        // setup contract name + contract symbol
        contractName = _name;
        contractSymbol = _symbol;

        // setup contract level logic
        contractLevelLogic = _contractLevelLogic;

        // initialize contract level logic if init not zero
        if (_contractLevelLogicInit.length != 0) {
            IContractLogic(_contractLevelLogic).initializeWithData(_contractLevelLogicInit);
        }
    }

    /// @notice Allows user to mint token(s) from the Press contract
    /// @param mintRecipients address to mint NFTs to
    /// @param mintQuantities number of NFTs to mint
    /// @param logics logic contracts to associate with a given token
    /// @param logicInits logicInit data to associate with a given logic contract
    /// @param renderers renderer contracts to associate with a given token
    /// @param rendererInits rendererInit data to associate with a given renderer contract
    function mintNewWithData(
        address[] memory mintRecipients, 
        uint256[] memory mintQuantities, 
        ILogic[] memory logics,
        bytes[] memory logicInits,
        IRenderer[] memory renderers,
        bytes[] memory rendererInits
    )
        external
        nonReentrant
        returns (uint256[] memory tokenIds)
    {

        // Call contract level logic contract to check if user can mint
        if (IContractLogic(contractLevelLogic).canMintNew(address(this), mintQuantities, mintRecipients, msg.sender) != true) {
            revert No_MintNew_Access();
        }        

        if (mintRecipients.length > 1) {
            // Multiple receivers.  Mint every receiver the same or diff quantities of the same new token
            // * not sure about render length here? why can it be 0? also shouldnt it be able to be same length as other stuff?
            // * also need to add in checks about logic files
            tokenIds = new uint256[](1);
            require(renderers.length <= 1 && (mintQuantities.length == 1 || mintRecipients.length == mintQuantities.length), "Invalid input");
        } else {
            // Single receiver.  Generating multiple tokens
            // * but couldnt they be not minting any tokens to ppl if quantity set to 0?
            // * maybe setting tokens to 0 is what enbles lazy minting, but imo we should mint the first token to ppl by defauly
            tokenIds = new uint256[](mintQuantities.length);
            require(renderers.length == 0 || mintQuantities.length == renderers.length, "Invalid input");
        }

        // Assign tokenIds
        for (uint i; i < tokenIds.length;) {
            ++_tokenCount;
            tokenIds[i] = _tokenCount;
            unchecked { ++i; }
        }        

        if (mintRecipients.length == 1 && tokenIds.length == 1) {
           // Single mint
            _mint(mintRecipients[0], tokenIds[0], mintQuantities[0], new bytes(0));
        } else if (mintRecipients.length > 1) {
            // Multiple receivers.  Receiving the same token
            if (mintQuantities.length == 1) {
                // Everyone receiving the same amount
                for (uint i; i < mintRecipients.length;) {
                    _mint(mintRecipients[i], tokenIds[0], mintQuantities[0], new bytes(0));
                    unchecked { ++i; }
                }
            } else {
                // Everyone receiving different mintQuantities
                for (uint i; i < mintRecipients.length;) {
                    _mint(mintRecipients[i], tokenIds[0], mintQuantities[i], new bytes(0));
                    unchecked { ++i; }
                }
            }
        } else {
            _mintBatch(mintRecipients[0], tokenIds, mintQuantities, new bytes(0));
        }

        // Assign + innitialize logics
        for (uint i; i < tokenIds.length;) {
            if (i < logics.length) {
                
                config[tokenIds[i]].logic = address(logics[i]);

                if (logicInits[i].length != 0) {
                    ILogic(logics[i]).initializeWithData(logicInits[i]);
                }
                
            }
            unchecked { ++i; }
        }

        // Assign + initialize renderers
        for (uint i; i < tokenIds.length;) {
            if (i < renderers.length) {

                config[tokenIds[i]].renderer = address(renderers[i]);

                if (rendererInits[i].length != 0) {
                    IRenderer(renderers[i]).initializeTokenMetadata(rendererInits[i]);
                }
                
            }
            unchecked { ++i; }
        }
    }


    /**
     * @dev Mint existing tokens
     */
    function _mintExisting(address[] memory to, uint256[] memory tokenIds, uint256[] memory amounts) internal {

        // Call contract => token level logic contract to check if user can mint
        if (IERC1155Logic(config[]).canMintNew(address(this), mintQuantities, mintRecipients, msg.sender) != true) {
            revert No_MintNew_Access();
        }             

        if (to.length == 1 && tokenIds.length == 1 && amounts.length == 1) {
             // Single mint
            _mint(to[0], tokenIds[0], amounts[0], new bytes(0));            
        } else if (to.length == 1 && tokenIds.length == amounts.length) {
            // Batch mint to same receiver
            _mintBatch(to[0], tokenIds, amounts, new bytes(0));
        } else if (tokenIds.length == 1 && amounts.length == 1) {
            // Mint of the same token/token amounts to various receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[0], amounts[0], new bytes(0));
                unchecked { ++i; }
            }
        } else if (tokenIds.length == 1 && to.length == amounts.length) {
            // Mint of the same token with different amounts to different receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[0], amounts[i], new bytes(0));
                unchecked { ++i; }
            }
        } else if (to.length == tokenIds.length && to.length == amounts.length) {
            // Mint of different tokens and different amounts to different receivers
            for (uint i; i < to.length;) {
                _mint(to[i], tokenIds[i], amounts[i], new bytes(0));
                unchecked { ++i; }
            }
        } else {
            revert("Invalid input");
        }
    }

}

/* references
oz https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC1155/ERC1155Upgradeable.sol
manifold https://github.com/manifoldxyz/creator-core-solidity/blob/main/contracts/ERC1155CreatorImplementation.sol
thirdweb https://github.com/thirdweb-dev/contracts/blob/main/contracts/drop/DropERC1155.sol
solmate https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol

manifold erc1155 lazypayble claim https://etherscan.io/address/0x44e94034AFcE2Dd3CD5Eb62528f239686Fc8f162#code

*/