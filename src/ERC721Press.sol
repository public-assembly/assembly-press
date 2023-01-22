// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";

import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IERC721Press} from "./interfaces/IERC721Press.sol";
import {ILogic} from "./interfaces/ILogic.sol";
import {IOwnableUpgradeable} from "./interfaces/IOwnableUpgradeable.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";

import {OwnableUpgradeable} from "./utils/OwnableUpgradeable.sol";
import {Version} from "./utils/Version.sol";

import {ERC721PressStorageV1} from "./storage/ERC721PressStorageV1.sol";

/**
 * @title ERC721Press
 * @notice A highly extensible ERC721A implementation
 * @dev Functionality is configurable using external renderer + logic contracts
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721Press is
    ERC721AUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable,
    IERC721Press,
    OwnableUpgradeable,
    Version(1),
    ERC721PressStorageV1
{
    /// @dev Recommended max mint batch size for ERC721A
    uint256 internal immutable MAX_MINT_BATCH_SIZE = 8;

    /// @dev Gas limit to send funds
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    /// @dev Max royalty basis points (BPS)
    uint16 constant MAX_ROYALTY_BPS = 50_00;

    /**
     * @dev Local fallback value for maxSupply to protect against broken logic
     *      being introduced by an external logic contract
     *      type(uint64).max == 18446744073709551615
     */
    uint64 maxSupplyFallback = type(uint64).max;

    uint8 randomVar;

    // constructor(uint8 _randomVar) initializer {
    //     _randomVar = randomVar;
    // }

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    ///  @notice Initializes a new, creator-owned proxy of ERC721Press.sol
    ///  @dev Optional primarySaleFeeBPS + primarySaleFeeRecipient
    ///       cannot be adjusted after initialization
    ///  @dev initializerERC721A for ERC721AUpgradeable
    //        initializer` for OpenZeppelin's OwnableUpgradeable
    ///  @param _contractName Contract name
    ///  @param _contractSymbol Contract symbol
    ///  @param _initialOwner User that owns the contract upon deployment
    ///  @param _fundsRecipient Address that receives funds from sale
    ///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    ///  @param _logic Logic contract to use (access control + pricing dynamics)
    ///  @param _logicInit Logic contract initial data
    ///  @param _renderer Renderer contract to use
    ///  @param _rendererInit Renderer initial data
    ///  @param _primarySaleFeeBPS Optional fee to set on primary sales
    ///  @param _primarySaleFeeRecipient Funds recipient on primary sales
    function initialize(
        string memory _contractName,
        string memory _contractSymbol,
        address _initialOwner,
        address payable _fundsRecipient,
        uint16 _royaltyBPS,
        ILogic _logic,
        bytes memory _logicInit,
        IRenderer _renderer,
        bytes memory _rendererInit,
        uint16 _primarySaleFeeBPS,
        address payable _primarySaleFeeRecipient
    ) public initializerERC721A initializer {
        // Setup ERC721A
        __ERC721A_init(_contractName, _contractSymbol);

        // Setup reentrancy guard
        __ReentrancyGuard_init();

        // Set ownership to original sender of contract call
        __Ownable_init(_initialOwner);

        // Check if fundsRecipient, logic, or renderer are being set to the zero address
        if (_fundsRecipient == address(0) || address(_logic) == address(0) || address(_renderer) == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Check if _royaltyBPS is higher than immutable MAX_ROYALTY_BPS value
        if (_royaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // Setup config variables
        config.fundsRecipient = _fundsRecipient;
        config.royaltyBPS = _royaltyBPS;
        config.logic = address(_logic);
        config.renderer = address(_renderer);

        // Initialize renderer + logic
        _logic.initializeWithData(_logicInit);
        _renderer.initializeWithData(_rendererInit);

        // Setup optional primary sales fee, skip if primarySalefeeBPS is set to zero
        if (_primarySaleFeeBPS != 0) {
            // Cannot set primarySaleFeeRecipient to zero address if feeBPS does not equal zero
            if (_primarySaleFeeRecipient == address(0)) {
                revert Cannot_Set_Zero_Address();
            }

            // Update primarySaleFeeDetails storage values, can only be done once
            primarySaleFeeDetails.feeBPS = _primarySaleFeeBPS;
            primarySaleFeeDetails.feeRecipient = _primarySaleFeeRecipient;

            emit IERC721Press.PrimarySaleFeeSet({feeRecipient: _primarySaleFeeRecipient, feeBPS: _primarySaleFeeBPS});
        }

        emit IERC721Press.ConfigInitialized({
            sender: msg.sender,
            logic: address(_logic),
            renderer: address(_renderer),
            fundsRecipient: _fundsRecipient,
            royaltyBPS: _royaltyBPS
        });
    }

    // ||||||||||||||||||||||||||||||||
    // ||| MINTING LOGIC ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows user to mint token(s) from the Press contract
    /// @param recipient address to mint NFTs to
    /// @param mintQuantity number of NFTs to mint
    /// @param mintData metadata to associate with the minted token(s)
    function mintWithData(address recipient, uint64 mintQuantity, bytes memory mintData)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        // Call logic contract to check if user can mint
        if (ILogic(config.logic).canMint(address(this), mintQuantity, msg.sender) != true) {
            revert No_Mint_Access();
        }

        // Call logic contract to check what mintPrice is for given quantity + user
        if (msg.value != ILogic(config.logic).totalMintPrice(address(this), mintQuantity, msg.sender)) {
            revert Incorrect_Msg_Value();
        }

        // Check if recipient is the zero address
        if (recipient == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Batch mint NFTs to recipient address
        _mintNFTs(recipient, mintQuantity);

        // Cache tokenId of first minted token so tokenId mint range can be reconstituted using events
        uint256 firstMintedTokenId = lastMintedTokenId() - mintQuantity;

        // Initialize the token's metadata if mintData is not empty
        if (mintData.length != 0) {
            IRenderer(config.renderer).initializeTokenMetadata(mintData);
        }

        emit IERC721Press.MintWithData({
            recipient: msg.sender,
            quantity: mintQuantity,
            mintData: mintData,
            totalMintPrice: msg.value,
            firstMintedTokenId: firstMintedTokenId
        });

        return firstMintedTokenId;
    }

    /// @notice Function to mint NFTs
    /// @dev (Important: Does not enforce max supply limit, enforce that limit earlier)
    /// @dev This batches in size of 8 as recommended by Chiru Labs
    /// @param to address to mint NFTs to
    /// @param quantity number of NFTs to mint
    function _mintNFTs(address to, uint256 quantity) internal {
        do {
            uint256 toMint = quantity > MAX_MINT_BATCH_SIZE ? MAX_MINT_BATCH_SIZE : quantity;
            _mint({to: to, quantity: toMint});
            quantity -= toMint;
        } while (quantity > 0);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| CONTRACT OWNERSHIP |||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Set new owner for access control + frontends
    /// @param newOwner address of the new owner
    function setOwner(address newOwner) public {
        // Check if msg.sender can transfer ownership
        if (msg.sender != owner() && ILogic(config.logic).canTransfer(address(this), msg.sender) != true) {
            revert No_Transfer_Access();
        }

        // Transfer contract ownership to new owner
        _transferOwnership(newOwner);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| CONFIG ACCESS ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Function to set config.fundsRecipient
    /// @dev Cannot set `fundsRecipient` to the zero address
    /// @param newFundsRecipient payable address to receive funds via withdraw
    function setFundsRecipient(address payable newFundsRecipient) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (ILogic(config.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert No_Update_Access();
        }

        // Check if `newFundsRecipient` is the zero address
        if (newFundsRecipient == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Update `fundsRecipient` address in config
        config.fundsRecipient = newFundsRecipient;

        emit UpdatedFundsRecipient({sender: msg.sender, fundsRecipient: newFundsRecipient});
    }

    /// @notice Function to set config.royaltyBPS
    /// @dev Max value = 5000
    /// @param newRoyaltyBPS uint16 value of `royaltyBPS`
    function setRoyaltyBPS(uint16 newRoyaltyBPS) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (ILogic(config.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert No_Update_Access();
        }

        // Check if `newRoyaltyBPS` is higher than immutable `MAX_ROYALTY_BPS` value
        if (newRoyaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // Update `royaltyBPS in config
        config.royaltyBPS = newRoyaltyBPS;

        emit UpdatedRoyaltyBPS({sender: msg.sender, royaltyBPS: newRoyaltyBPS});
    }

    /// @notice Function to set config.logic
    /// @dev Cannot set logic to the zero address
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setLogic(address newLogic, bytes memory newLogicInit) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (ILogic(config.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert No_Update_Access();
        }

        // Check if `newLogic` is the zero address
        if (newLogic == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Update logic contract address in config
        config.logic = newLogic;

        // Call initializeWithData if `newLogicInit` is not empty
        if (newLogicInit.length != 0) {
            ILogic(newLogic).initializeWithData(newLogicInit);
        }

        emit UpdatedLogic({sender: msg.sender, logic: newLogic});
    }

    /// @notice Function to set config.renderer
    /// @dev Cannot set renderer to the zero address
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    function setRenderer(address newRenderer, bytes memory newRendererInit) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (ILogic(config.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert No_Update_Access();
        }

        // Check if newRenderer is the zero address
        if (newRenderer == address(0)) {
            revert Cannot_Set_Zero_Address();
        }

        // Update renderer address in config
        config.renderer = newRenderer;

        // Call `initializeWithData` if newRendererInit is not empty
        if (newRendererInit.length != 0) {
            IRenderer(newRenderer).initializeWithData(newRendererInit);
        }

        emit UpdatedRenderer({sender: msg.sender, renderer: newRenderer});
    }

    /// @notice Function to set config.logic
    /// @dev Cannot set fundsRecipient or logic or renderer to address(0)
    /// @dev Max `newRoyaltyBPS` value = 5000
    /// @param newFundsRecipient payable address to recieve funds via withdraw
    /// @param newRoyaltyBPS uint16 value of royaltyBPS
    /// @param newRenderer renderer address to handle metadata logic
    /// @param newRendererInit data to initialize renderer
    /// @param newLogic logic address to handle general contract logic
    /// @param newLogicInit data to initialize logic
    function setConfig(
        address payable newFundsRecipient,
        uint16 newRoyaltyBPS,
        address newRenderer,
        bytes memory newRendererInit,
        address newLogic,
        bytes memory newLogicInit
    ) external nonReentrant {
        // Call logic contract to check is msg.sender can update
        if (ILogic(config.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert No_Update_Access();
        }

        (bool setSuccess) =
            _setConfig(newFundsRecipient, newRoyaltyBPS, newRenderer, newRendererInit, newLogic, newLogicInit);

        // Check if config update was successful
        if (!setSuccess) {
            revert Set_Config_Fail();
        }

        emit UpdatedConfig({
            sender: msg.sender,
            logic: newLogic,
            renderer: newRenderer,
            fundsRecipient: newFundsRecipient,
            royaltyBPS: newRoyaltyBPS
        });
    }

    /// @notice Internal handler to set config.logic
    function _setConfig(
        address payable newFundsRecipient,
        uint16 newRoyaltyBPS,
        address newRenderer,
        bytes memory newRendererInit,
        address newLogic,
        bytes memory newLogicInit
    ) internal returns (bool) {
        // Check if supplied addresses are the zero address
        if (newFundsRecipient == address(0) || newRenderer == address(0) || newLogic == address(0)) {
            revert Cannot_Set_Zero_Address();
        }
        // Check if newRoyaltyBPS is higher than immutable MAX_ROYALTY_BPS value
        if (newRoyaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // Update fundsRecipient address in config
        config.fundsRecipient = newFundsRecipient;

        // Update royaltyBPS in config
        config.royaltyBPS = newRoyaltyBPS;

        // Update renderer address in config
        config.renderer = newRenderer;

        // Call initializeWithData if newRendererInit is not empty
        if (newRendererInit.length != 0) {
            IRenderer(newRenderer).initializeWithData(newRendererInit);
        }

        // Update logic contract address in config
        config.logic = newLogic;

        // Call initializeWithData if newLogicInit is not empty
        if (newLogicInit.length != 0) {
            ILogic(newLogic).initializeWithData(newLogicInit);
        }

        return true;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| PAYOUTS + ROYALTIES ||||||||
    // ||||||||||||||||||||||||||||||||

    function withdraw() external nonReentrant {
        address sender = msg.sender;

        // Check if withdraw is allowed for sender
        if (sender != owner() && ILogic(config.logic).canWithdraw(address(this), sender) != true) {
            revert No_Withdraw_Access();
        }

        // Calculate primary sale fee amount
        uint256 funds = address(this).balance;
        uint256 fee = funds * primarySaleFeeDetails.feeBPS / 10_000;

        // Payout primary sale fees
        if (fee > 0) {
            (bool successFee,) = primarySaleFeeDetails.feeRecipient.call{value: fee, gas: FUNDS_SEND_GAS_LIMIT}("");
            if (!successFee) {
                revert Withdraw_FundsSendFailure();
            }
            funds -= fee;
        }

        // Payout recipient
        (bool successFunds,) = config.fundsRecipient.call{value: funds, gas: FUNDS_SEND_GAS_LIMIT}("");
        if (!successFunds) {
            revert Withdraw_FundsSendFailure();
        }

        emit FundsWithdrawn(msg.sender, config.fundsRecipient, funds, primarySaleFeeDetails.feeRecipient, fee);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ERC721A CUSTOMIZATION ||||||
    // ||||||||||||||||||||||||||||||||

    /* TODO: Confirm that the canBurn check is actually what is gating burn success */

    /// @notice User burn function for tokenId
    /// @param tokenId token id to burn
    function burn(uint256 tokenId) public {
        // Check if burn is allowed for sender
        if (ILogic(config.logic).canBurn(address(this), msg.sender) != true) {
            revert No_Burn_Access();
        }

        _burn(tokenId, true);
    }

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @notice Getter for last minted token id (gets next token id and subtracts 1)
    /// @dev Also works as a "totalMinted" lookup
    function lastMintedTokenId() public view returns (uint256) {
        return _nextTokenId() - 1;
    }

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256) {
        return _numberMinted(ownerAddress);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| PUBLIC VIEW CALLS ||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Simple override for owner interface
    function owner() public view override(OwnableUpgradeable, IERC721Press) returns (address) {
        return super.owner();
    }

    /// @notice Contract uri getter
    /// @dev Call proxies to renderer
    function contractURI() external view returns (string memory) {
        return IRenderer(config.renderer).contractURI();
    }

    /// @notice Token uri getter
    /// @dev Call proxies to renderer
    /// @param tokenId id of token to get the uri for
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        /// Reverts if the supplied token does not exist
        if (!_exists(tokenId)) {
            revert IERC721AUpgradeable.URIQueryForNonexistentToken();
        }

        return IRenderer(config.renderer).tokenURI(tokenId);
    }

    /// @notice Getter for fundsRecipent address stored in config
    /// @dev May return 0 or revert if incorrect external logic has been configured
    /// @dev Can use maxSupplyFallback instead in the above scenario
    function maxSupply() external view returns (uint64) {
        return ILogic(config.logic).maxSupply();
    }

    /// @notice Getter for fundsRecipent address stored in config
    function fundsRecipient() external view returns (address payable) {
        return config.fundsRecipient;
    }

    /// @notice Getter for logic contract stored in config
    function royaltyBPS() external view returns (uint16) {
        return config.royaltyBPS;
    }

    /// @notice Getter for renderer contract stored in config
    function renderer() external view returns (IRenderer) {
        return IRenderer(config.renderer);
    }

    /// @notice Getter for logic contract stored in config
    function logic() external view returns (ILogic) {
        return ILogic(config.logic);
    }

    /// @notice Config details
    /// @return IERC721Press.Configuration details
    function configDetails() external view returns (IERC721Press.Configuration memory) {
        return IERC721Press.Configuration({
            fundsRecipient: config.fundsRecipient,
            royaltyBPS: config.royaltyBPS,
            logic: config.logic,
            renderer: config.renderer
        });
    }

    /// @notice Getter for `feeRecipient` address stored in `primarySaleFeeDetails`
    function primarySaleFeeRecipient() external view returns (address payable) {
        return primarySaleFeeDetails.feeRecipient;
    }

    /// @notice Getter for `feeBPS` stored in `primarySaleFeeDetails`
    function primarySaleFeeBPS() external view returns (uint16) {
        return primarySaleFeeDetails.feeBPS;
    }

    /// @notice PrimarySaleFee details
    /// @return IERC721Press.PrimarySaleFee details
    function primarySaleFeeConfig() external view returns (IERC721Press.PrimarySaleFee memory) {
        return IERC721Press.PrimarySaleFee({
            feeRecipient: primarySaleFeeDetails.feeRecipient,
            feeBPS: primarySaleFeeDetails.feeBPS
        });
    }

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165Upgradeable, ERC721AUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || type(IOwnableUpgradeable).interfaceId == interfaceId
            || type(IERC2981Upgradeable).interfaceId == interfaceId || type(IERC721Press).interfaceId == interfaceId;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| MISC |||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev Get royalty information for token
    /// @param _salePrice sale price for the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (config.fundsRecipient == address(0)) {
            return (config.fundsRecipient, 0);
        }
        return (config.fundsRecipient, (_salePrice * config.royaltyBPS) / 10_000);
    }

    /// @dev Can only be called by an admin or the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override canUpgrade {}

    modifier canUpgrade() {
        // call logic contract to check is msg.sender can upgrade
        if (ILogic(config.logic).canUpgrade(address(this), msg.sender) != true && owner() != msg.sender) {
            revert No_Upgrade_Access();
        }

        _;
    }
}
