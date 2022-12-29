// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
Assembly Press
An information distribution framework
*/

import {ERC721AUpgradeable} from "erc721a-upgradeable/ERC721AUpgradeable.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableSkeleton} from "./utils/OwnableSkeleton.sol";
import {IPress} from "./interfaces/IPress.sol";
import {ILogic} from "./interfaces/ILogic.sol";
import {IOwnable} from "./interfaces/IOwnable.sol";
import {IRenderer} from "./interfaces/IRenderer.sol";
import {PressStorageV1} from "./storage/PressStorageV1.sol";


/**
 * @notice minimal NFT Base contract in AssemblyPress framework
 *      injected with metadata + minting + access control logic during deploy from AssemblyPress
 * @dev 
 * @author FF89de.eth
 *
 */
contract Press is 
    ERC721AUpgradeable,
    UUPSUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable,    
    IPress,
    OwnableSkeleton,
    PressStorageV1
{

    /* EDITS TO MAKE

    ADD IN CONFIGURABLE DEPLOYER FEEEEEEEE

    Quesetions
    - do we like how _authorizeUpgrade is handled? didn't use ZORA upgradeArch, but looks like
        we are missing the functionaity thats provided in the zora upgrade gate
        https://github.com/ourzora/zora-drops-contracts/blob/main/src/FactoryUpgradeGate.sol
    - do we like how we implemented a very basic optional primary sale fee incentive mechanism
        completely optional, but allows front end create services to set themselves an immutable fee
        upon contract deploy that gets paid out permissionlessly on withdraw

    1. Determine if need to add in any missing erc721 util functionality like "burn"
    2. add ability to withdraw non ETH funds
        -- does contract need FundsReciever import?
    3. add back in upgradeablility + proxy set up
    */

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @dev This is the max mint batch size for the optimized ERC721A mint contract
    uint256 internal immutable MAX_MINT_BATCH_SIZE = 8;

    /// @dev Gas limit to send funds
    uint256 internal immutable FUNDS_SEND_GAS_LIMIT = 210_000;

    /// @notice Max royalty BPS
    uint16 constant MAX_ROYALTY_BPS = 50_00;    

    // ===== ERRORS

    // ===== EVENTS

    // ===== CONSTRUCTOR

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||    

    ///  @dev Create a new press contract for media publication
    ///  @dev primarySaleFeeBPS + primarySaleFeeRecipient cannot be adjusted after initialization
    ///  @param _contractName Contract name
    ///  @param _contractSymbol Contract symbol
    ///  @param _initialOwner User that owns the contract upon deployment
    ///  @param _fundsRecipient Wallet address that receives funds from sale
    ///  @param _royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty.
    ///  @param _logic Logic contract to use (access control + pricing dynamics)
    ///  @param _logicInit Logic contract initial data   
    ///  @param _renderer Renderer contract to use
    ///  @param _rendererInit Renderer initial data
    ///  @param _primarySaleFeeBPS optional fee to set on primary sales
    ///  @param _primarySaleFeeRecipient fundsRecipient on primary sales
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
    ) public initializer {
        // Setup ERC721A
        __ERC721A_init(_contractName, _contractSymbol);
        // Setup re-entracy guard
        __ReentrancyGuard_init();
        // Set ownership to original sender of contract call
        _setOwner(_initialOwner);

        // check if fundsRecipient, logic, or renderer are being set to address(0)
        if (_fundsRecipient == address(0) || address(_logic) == address(0) 
            || address(_renderer) == address(0)) 
        {
            revert CANNOT_SET_ZERO_ADDRESS();
        }        

        // check if _royaltyBPS is higher than immutable MAX_ROYALTY_BPS value
        if (_royaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // Setup pressConfig variables
        pressConfig.fundsRecipient = _fundsRecipient;
        pressConfig.royaltyBPS = _royaltyBPS;
        pressConfig.logic = address(_logic);   
        pressConfig.renderer = address(_renderer);

        // initialize renderer + logic
        _logic.initializeWithData(_logicInit);        
        _renderer.initializeWithData(_rendererInit);

        // Setup optional primary sales fee, skip if feeBPS = 0
        if (_primarySaleFeeBPS != 0) {

            // cannot set primarySaleFeeRecipient to zero address if feeBPS != 0
            if (_primarySaleFeeRecipient != address(0)) {
                revert CANNOT_SET_ZERO_ADDRESS();
            }

            // update primarySaleFee storage values. immutable once
            primarySaleFee.feeBPS = _primarySaleFeeBPS;
            primarySaleFee.fundsRecipient = _primarySaleFeeRecipient;
        }
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| MINTING LOGIC ||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice allows user to mint token(s) from the Press contract
    function mintWithData(address recipient, uint64 mintQuantity, bytes memory mintData)
        external
        payable
        nonReentrant
    {
        // call logic contract to check is user can mint
        if(ILogic(pressConfig.logic).canMint(address(this), mintQuantity, msg.sender) != true) {
            revert CANNOT_MINT();
        }

        // call logic contract to check what mintPrice is for given quantity + user
        if(msg.value != ILogic(pressConfig.logic).totalMintPrice(address(this), mintQuantity, msg.sender)) {
            revert INCORRECT_MSG_VALUE();
        }        

        // batch mint NFTs to recipient address
        _mintNFTs(recipient, mintQuantity);

        // call initializeTokenMetadata if mintData != 0
        if (mintData.length != 0) {
            IRenderer(pressConfig.renderer).initializeTokenMetadata(mintData);
        }
    }

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

    // ||||||||||||||||||||||||||||||||
    // ||| PressConfig ADMIN ||||||||||
    // ||||||||||||||||||||||||||||||||
    
    function setFundsRecipient(address payable newFundsRecipient)
        external
        nonReentrant
    {
        // call logic contract to check is msg.sender can update
        if(ILogic(pressConfig.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert NO_UPDATE_ACCESS();
        }        

        // check if newFundsRecipient == zero address
        if(newFundsRecipient == address(0)) {
            revert CANNOT_SET_ZERO_ADDRESS();
        }

        // update fundsRecipient address in pressConfig
        pressConfig.fundsRecipient = newFundsRecipient;
    }

    function setRoyaltyBPS(uint16 newRoyaltyBPS)
        external
        nonReentrant
    {
        // call logic contract to check is msg.sender can update
        if(ILogic(pressConfig.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert NO_UPDATE_ACCESS();
        }        

        // check if newRoyaltyBPS is higher than immutable MAX_ROYALTY_BPS value
        if (newRoyaltyBPS > MAX_ROYALTY_BPS) {
            revert Setup_RoyaltyPercentageTooHigh(MAX_ROYALTY_BPS);
        }

        // update fundsRecipient address in pressConfig
        pressConfig.royaltyBPS = newRoyaltyBPS;
    }    


    function setRenderer(address newRenderer, bytes memory newRendererInit)
        external
        nonReentrant
    {
        // call logic contract to check is msg.sender can update
        if(ILogic(pressConfig.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert NO_UPDATE_ACCESS();
        }        

        // update renderer address in pressConfig
        pressConfig.renderer = newRenderer;

        // call initializeWithData if newRendererInit != 0
        if (newRendererInit.length > 0) {
            IRenderer(newRenderer).initializeWithData(newRendererInit);
        }        
    }

    function setLogic(address newLogic, bytes memory newLogicInit)
        external
        nonReentrant
    {
        // call logic contract to check is msg.sender can update
        if(ILogic(pressConfig.logic).canUpdatePressConfig(address(this), msg.sender) != true) {
            revert NO_UPDATE_ACCESS();
        }        

        // update logic contract address in pressConfig
        pressConfig.logic = newLogic;

        // call initializeWithData if newLogicInit != 0
        if (newLogicInit.length > 0) {
            ILogic(newLogic).initializeWithData(newLogicInit);
        }     
    }            

    // ===== OTHER UTILS

    function withdraw() external nonReentrant {
        address sender = msg.sender;

        // Check if withdraw is allowed for sender
        if (
            sender != owner() &&
            ILogic(pressConfig.logic).canWithdraw(address(this), sender) != true
        ) {
            revert NO_WITHDRAW_ACCESS();
        }    

        // Calculate primary sale fee amount
        uint256 funds = address(this).balance;
        uint256 fee = funds * primarySaleFee.feeBPS / 10_000;

        // Payout primary sale fees
        if (fee > 0) {
            (bool successFee, ) = primarySaleFee.fundsRecipient.call{
                value: fee,
                gas: FUNDS_SEND_GAS_LIMIT
            }("");
            if (!successFee) {
                revert Withdraw_FundsSendFailure();
            }
            funds -= fee;
        } 

        // Payout recipient
        (bool successFunds, ) = pressConfig.fundsRecipient.call{
            value: funds,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");
        if (!successFunds) {
            revert WITHDRAW_FUNDS_SEND_FAILURE();
        }          

        // // Emit event for indexing
        // emit FundsWithdrawn(
        //     msg.sender,
        //     pressConfig.fundsRecipient,
        //     funds,
        //     primarySaleFee,
        //     parimarySaleFeeRecipient,
        // );
    }    

    /// @dev Get royalty information for token
    /// @param _salePrice Sale price for the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (pressConfig.fundsRecipient == address(0)) {
            return (pressConfig.fundsRecipient, 0);
        }
        return (
            pressConfig.fundsRecipient,
            (_salePrice * pressConfig.royaltyBPS) / 10_000
        );
    }    

    /// @notice Connects this contract to the factory upgrade gate
    /// @param newImplementation proposed new upgrade implementation
    /// @dev Only can be called by admin
    function _authorizeUpgrade(address newImplementation)
        internal
        override
    {
        // call logic contract to check is msg.sender can upgrade
        if(
            ILogic(pressConfig.logic).canUpgrade(address(this), msg.sender) != true
                && owner() != msg.sender
        ) {
            revert NO_UPGRADE_ACCESS();
        }
    }


    // ===== ERC721A EXTENDED FUNCTIONALITY

    /// @notice Start token ID for minting (1-100 vs 0-99)
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }    

    /// @notice Getter for last minted token ID (gets next token id and subtracts 1)
    /// @dev also works as a "totalMinted" lookup
    function lastMintedTokenId() external view returns (uint256) {
        return _nextTokenId() - 1;
    }

    /// @notice Getter that returns number of tokens minted for a given address
    function numberMinted(address ownerAddress) external view returns (uint256) {
        return _numberMinted(ownerAddress);
    }

    // ===== PUBLIC GETTERS

    /// @notice Simple override for owner interface.
    /// @return user owner address
    function owner()
        public
        view
        override(OwnableSkeleton, IPress)
        returns (address)
    {
        return super.owner();
    }    

    /// @notice Getter for renderer contract
    function renderer() external view returns (IRenderer) {
        return IRenderer(pressConfig.renderer);
    }

    /// @notice Getter for logic contract
    function logic() external view returns (ILogic) {
        return ILogic(pressConfig.logic);
    }    

    // /// @notice Getter for entire pressConfig
    // function pressDetails() external view returns (IRenderer, IMintingLogic, IAccessControl) {
    //     return ( 
    //         IPress(pressConfig.renderer),
    //         IPress(pressConfig.mintingLogic),
    //         IPress(pressConfig.accessControl)
    //     );
    // }    

    /// @notice Contract URI Getter, proxies to renderer
    /// @return Contract URI
    function contractURI() external view returns (string memory) {
        return IRenderer(pressConfig.renderer).contractURI();
    }

    /// @notice Token URI Getter, proxies to renderer
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

        return IRenderer(pressConfig.renderer).tokenURI(tokenId);
    }    

    /// @notice ERC165 supports interface
    /// @param interfaceId interface id to check if supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(
            IERC165Upgradeable,
            ERC721AUpgradeable
        )
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            type(IOwnable).interfaceId == interfaceId ||
            type(IERC2981Upgradeable).interfaceId == interfaceId ||
            type(IPress).interfaceId == interfaceId;
    }

}
    