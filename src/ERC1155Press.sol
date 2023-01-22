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

/**
 * @title ERC1155Press
 * @notice A highly extensible ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155Upgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    Version(1)
{
    /// @dev Max royalty basis points (BPS)
    uint16 constant MAX_ROYALTY_BPS = 50_00;

    // contract name + contract symbol
    string public contractName;
    string public contractSymbol;

    // contract level secondary royaltyBPS
    /* is there a way to get this down to token level? */
    // track it down starting line 57 https://github.com/manifoldxyz/creator-core-solidity/blob/648ef7aa1a7442416b49de35b9e2411fce23b419/contracts/core/CreatorCore.sol
    uint16 royaltyBPS;

    // custom counter since cant use ERC721A's
    uint256 internal _tokenCount = 0;


    /**
     * Initializer
     */
    ///  @param _name Contract name
    ///  @param _symbol Contract symbol
    ///  @param _initialOwner User that owns the contract upon deployment  
    ///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty   
    function initialize(
        string memory _name, 
        string memory _symbol, 
        address _initialOwner,
        uint16 _royaltyBPS
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

        // setup contract level secondary royaltyBPS
        royaltyBPS = _royaltyBPS;
    }


    /// @notice Allows user to mint token(s) from the Press contract
    /// @param recipients address to mint NFTs to
    /// @param mintQuantities number of NFTs to mint
    /// @param logics logic contracts to associate with a given token
    /// @param logicInits logicInit data to associate with a given logic contract
    /// @param renderers renderer contracts to associate with a given token
    /// @param rendererInits rendererInit data to associate with a given renderer contract
    function mintNewWithData(
        address[] mintRecipients, 
        uint64[] mintQuantities, 
        address[] logics,
        bytes[] logicInits,
        address[] renderers,
        bytes[] rendererInits
    )
        external
        payable
        nonReentrant
        returns (uint256[] memory tokenIds)
    {

        // all of the logic about who gets what tokens
        /*
        follow manifold setup for help line 197 https://github.com/manifoldxyz/creator-core-solidity/blob/main/contracts/ERC1155CreatorUpgradeable.sol
        we could potentially be a bit more opinioanted here to simplify things

        NEEDS to include logic that determines how many new tokenIds are being minted
        including a simplified version for nwow
        */

        if (mintRecipients.length > 1) {
            // Multiple receiver.  Give every receiver the same new token
            tokenIds = new uint256[](1);
            require(renderers.length <= 1 && (mintQuantities.length == 1 || mintRecipients.length == mintQuantities.length), "Invalid input");
        } else {
            // Single receiver.  Generating multiple tokens
            tokenIds = new uint256[](mintQuantities.length);
            require(renderers.length == 0 || mintQuantities.length == renderers.length, "Invalid input");
        }

        // Assign tokenIds
        for (uint i; i < tokenIds.length;) {
            ++_tokenCount;
            tokenIds[i] = _tokenCount;
            // // Track the extension that minted the token
            // _tokensExtension[_tokenCount] = extension;
            unchecked { ++i; }
        }        


        /* this needs to be reconfigured below to allow for setting up the renderer
        contract so that the uri of that token gets proxied to in the uri call of this contract
        */
        // // all of the logic about setting up renderer + logic contracts
        // for (uint i; i < tokenIds.length;) {
        //     if (i < uris.length && bytes(uris[i]).length > 0) {
        //         _tokenURIs[tokenIds[i]] = uris[i];
        //     }
        //     unchecked { ++i; }
        // }
    }
}

/* references
oz https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC1155/ERC1155Upgradeable.sol
manifold https://github.com/manifoldxyz/creator-core-solidity/blob/main/contracts/ERC1155CreatorImplementation.sol
thirdweb https://github.com/thirdweb-dev/contracts/blob/main/contracts/drop/DropERC1155.sol
solmate https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol
*/