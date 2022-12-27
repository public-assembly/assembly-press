// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
Assembly Press:
An open media creation framework
*/

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {IPress} from "./interfaces/IPress.sol";
import {IMetadataRenderer} from "./interfaces/IMetadataRenderer.sol";
import {IMintingLogic} from "./interfaces/IMintingLogic.sol";
import {IAccessControl} from "./interfaces/IMetadataRenderer.sol";
import {OwnableSkeleton} from "./utils/OwnableSkeleton.sol";

/**
 * @notice minimal NFT Base contract in AssemblyPress framework
 *      injected with metadata + minting + access control logic during deploy from AssemblyPress
 * @dev 
 * @author FF89de.eth
 *
 */
contract Press is 
    ERC721AUpgradeable,
    IERC721AUpgradeable,
    IERC2981Upgradeable,
    IERC165Upgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    OwnableSkeleton,
    IPress
{
    // ===== STORAGE

    /// @dev This is the max mint batch size for the optimized ERC721A mint contract
    uint256 internal immutable MAX_MINT_BATCH_SIZE = 8;

    string contractURI = contractURI;

    // ===== ERRORS

    // ===== EVENTS

    // ===== CONSTRUCTOR

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    ///  @dev Create a new drop contract
    ///  @param _contractName Contract name
    ///  @param _contractSymbol Contract symbol
    ///  @param _initialOwner User that owns and can mint the edition, gets royalty and sales payouts and can update the base url if needed.
    ///  @param _fundsRecipient Wallet/user that receives funds from sale
    ///  @param _editionSize Number of editions that can be minted in total. If 0, unlimited editions can be minted.
    ///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
    ///  @param _salesConfig New sales config to set upon init
    ///  @param _metadataRenderer Renderer contract to use
    ///  @param _metadataRendererInit Renderer data initial contract
    function initialize(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        address payable _fundsRecipient,
        uint64 _editionSize,
        uint16 _royaltyBPS,
        SalesConfiguration memory _salesConfig,
        IMetadataRenderer _metadataRenderer,
        bytes memory _metadataRendererInit
    ) public initializer {
        // Setup ERC721A
        __ERC721A_init(_contractName, _contractSymbol);
        // Setup access control
        __AccessControl_init();
        // Setup re-entracy guard
        __ReentrancyGuard_init();
        // Set ownership to original sender of contract call
        _setOwner(_initialOwner);

        if (config.royaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // Update salesConfig
        salesConfig = _salesConfig;

        // Setup config variables
        config.editionSize = _editionSize;
        config.metadataRenderer = _metadataRenderer;
        config.royaltyBPS = _royaltyBPS;
        config.fundsRecipient = _fundsRecipient;
        _metadataRenderer.initializeWithData(_metadataRendererInit);


        // set up contractURI
        contractURI = _contractURI;

    }    

    // ||||||||||||||||||||||||||||||||
    // ||| PUBLIC WRITE FUNCTIONS |||||
    // ||||||||||||||||||||||||||||||||
    
    // ===== MINTING + SALES LOGIC

    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(address recipient, uint256 mintQuantity, bytes memory mintData)
        external
        payable
        nonReentrant
    {
        IPress(pressConfig.mintingLogic).mintWithData(mintData);

        _mintNFTs(recipient, mintQuantity);

        IMetadataRenderer(pressConfig.metadataRenderer).initializeWithData(mintData);
    }

    /// @notice allows user to mint token(s) from the Press contract
    function withdraw()
        external
        nonReentrant
    {
        IPress(pressConfig.mintingLogic).withdraw();
    }        

    // ===== POST MINT METADATA LOGIC   

    /// @notice allows user to edit tokens created the Press contract
    function editMetadata(bytes memory editData)
        external
        nonReentrant
    {
        IPress(pressConfig.metadataRenderer).editWithData(editData);
    }    

    // ===== ACCESS CONTROL LOGIC
    /// @notice allows user to edit access control for Press contract
    function editAccessControl(bytes memory accessControlData)
        external
        nonReentrant
    {
        IPress(pressConfig.accessControl).editWithData(editData);

        // ^ this function should not allow changing of the access control module in use
    }  

    // ===== PRESS CONFIG EDIT FUNCTIONS
    function newMetadataRenderer(address newRenderer, bytes memory newRendererInit)
        external
        nonReentrant
    {
        IPress(pressConfig.metadataRenderer) = newRenderer

        IMetadataRenderer(newRenderer).initializeWithData(newRendererInit)
    }

    // ===== PRESS CONFIG EDIT FUNCTIONS
    function newMintingLogic(address newMintingLogic, bytes memory newLogicInit)
        external
        nonReentrant
    {
        IPress(pressConfig.mintingLogic) = newMintingLogic

        IMintingLogic(newMintingLogic).initializeWithData(newLogicInit)
    }    

    // ===== PRESS CONFIG EDIT FUNCTIONS
    function newAccessControl(address newAccessControl, bytes memory newAccessInit)
        external
        nonReentrant
    {
        IPress(pressConfig.accessControl) = newAccessControl

        IAccessControl(newAccessControl).initializeWithData(newAccessInit)
    }        


    // ===== INTERNAL HELPERS

    /// @notice Function to mint NFTs
    /// @dev (important: Does not enforce max supply limit, enforce that limit earlier)
    /// @dev This batches in size of 8 as per recommended by ERC721A creators
    /// @param to address to mint NFTs to
    /// @param quantity number of NFTs to mint
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > MAX_MINT_BATCH_SIZE
                ? MAX_MINT_BATCH_SIZE
                : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }

    // ===== PUBLIC GETTERS

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }    

    /// @notice Simple override for owner interface.
    /// @return user owner address
    function owner()
        public
        view
        override(OwnableSkeleton)
        returns (address)
    {
        return super.owner();
    }    

    /// @notice Getter for metadataRenderer contract
    function metadataRenderer() external view returns (IMetadataRenderer) {
        return pressConfig.metadataRenderer;
    }

    /// @notice Getter for mintingLogic contract
    function mintingLogic() external view returns (IMintingLogic) {
        return pressConfig.mintingLogic;
    }    

    /// @notice Getter for accessControl contract
    function accessControl() external view returns (IAccessControl) {
        return pressConfig.accessControl;
    }        

    // /// @notice Getter for entire pressConfig
    // function pressDetails() external view returns (IMetadataRenderer, IMintingLogic, IAccessControl) {
    //     return ( 
    //         IPress(pressConfig.metadataRenderer),
    //         IPress(pressConfig.mintingLogic),
    //         IPress(pressConfig.accessControl)
    //     );
    // }    

    /// @notice Contract URI Getter, proxies to metadataRenderer
    /// @return Contract URI
    function contractURI() external view returns (string memory) {
        return pressConfig.metadataRenderer.contractURI();
    }

    /// @notice Token URI Getter, proxies to metadataRenderer
    /// @param tokenId id of token to get URI for
    /// @return Token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }

        return pressConfig.metadataRenderer.tokenURI(tokenId);
    }    
}
    