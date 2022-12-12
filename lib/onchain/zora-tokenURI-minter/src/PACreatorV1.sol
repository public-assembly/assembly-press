// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ZoraNFTCreatorProxy} from "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {TokenUriMinter} from "./TokenUriMinter.sol";
import {IZoraCreatorInterface} from "./interfaces/IZoraCreatorInterface.sol";

/**
 * @title PACreatorV1
 * @notice Facilitates deployment of custom ZORA drops with extended functionality
 * @notice not audited use at own risk
 * @author Max Bochman
 *
 */
contract PACreatorV1 is Ownable, ReentrancyGuard {

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||     

    error CantSet_ZeroAddress();

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||
 
    event ZoraProxyAddressInitialized(address zoraProxyAddress); 
    event ZoraProxyAddressUpdated(address sender, address newZoraProxyAddress); 

    event TokenUriMetadataRendererInitialized(address tokenUriMetadataRenderer); 
    event TokenUriMetadataRendererUpdated(address sender, address newTokenUriMetadataRenderer); 

    event TokenUriMinterInitialized(address tokenUriMinter); 
    event TokenUriMinterUpdated(address sender, address newTokenUriMinter);         

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      
    
    bytes32 public immutable DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");
    address public zoraNFTCreatorProxy;
    IMetadataRenderer public tokenUriMetadataRenderer;
    address public tokenUriMinter; 

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    constructor(
        address _zoraNFTCreatorProxy, 
        IMetadataRenderer _tokenUriMetadataRenderer, 
        address _tokenUriMinter 
    ) {
        zoraNFTCreatorProxy = _zoraNFTCreatorProxy;
        tokenUriMetadataRenderer = _tokenUriMetadataRenderer;
        tokenUriMinter = _tokenUriMinter;

        emit ZoraProxyAddressInitialized(zoraNFTCreatorProxy);
        emit TokenUriMetadataRendererInitialized(address(tokenUriMetadataRenderer));
        emit TokenUriMinterInitialized(tokenUriMinter);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| DEPLOY + CONFIGURE DROP ||||
    // |||||||||||||||||||||||||||||||| 

    function deployAndConfigureDrop(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory contractURI,
        address wildcardAddress,
        uint256 mintPricePerToken
    ) public nonReentrant returns (address) {

        // encode contractURI + wildcardAddress to pass into metadataRenderer
        bytes memory metadataInitializer = abi.encode(contractURI, wildcardAddress); 

        // deploy zora collection - defaultAdmin must be address(this) here but will be updated later
        address newDropAddress = IZoraCreatorInterface(zoraNFTCreatorProxy).setupDropsContract(
            name,
            symbol,
            address(this),
            editionSize,
            royaltyBPS,
            fundsRecipient,
            saleConfig,
            tokenUriMetadataRenderer,
            metadataInitializer           
        );

        // give tokenURIMinter minter role on zora drop
        ERC721Drop(payable(newDropAddress)).grantRole(MINTER_ROLE, tokenUriMinter);

        // set mintPricePerToken for zora drop
        TokenUriMinter(tokenUriMinter).setMintPrice(newDropAddress, mintPricePerToken);

        // grant admin role to desired admin address
        ERC721Drop(payable(newDropAddress)).grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        // revoke admin role from address(this) as it differed from desired admin address
        ERC721Drop(payable(newDropAddress)).revokeRole(DEFAULT_ADMIN_ROLE, address(this));

        return newDropAddress;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ADMIN FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @dev updates address value of zoraNFTCreatorProxy
    /// @param newZoraNFTCreatorProxy new zoraNFTCreatorProxy address
    function setZoraCreatorProxyAddress(address newZoraNFTCreatorProxy) public onlyOwner {

        if (newZoraNFTCreatorProxy == address(0)) {
            revert CantSet_ZeroAddress();
        }

        zoraNFTCreatorProxy = newZoraNFTCreatorProxy;

        emit ZoraProxyAddressUpdated(msg.sender, newZoraNFTCreatorProxy);
    }      

    /// @dev updates address value of tokenUriMetadataRenderer
    /// @param newTokenUriMetadataRenderer new tokenUriMetadataRenderer address
    function setTokenUriMetadataRendererAddress(IMetadataRenderer newTokenUriMetadataRenderer) public onlyOwner {

        if (address(newTokenUriMetadataRenderer) == address(0)) {
            revert CantSet_ZeroAddress();
        }

        tokenUriMetadataRenderer = newTokenUriMetadataRenderer;

        emit TokenUriMetadataRendererUpdated(msg.sender, address(newTokenUriMetadataRenderer));
    }     

    /// @dev updates address value of tokenUriMinter
    /// @param newTokenUriMinter new tokenUriMinter address
    function setTokenUriMinterAddress(address newTokenUriMinter) public onlyOwner {

        if (newTokenUriMinter == address(0)) {
            revert CantSet_ZeroAddress();
        }

        tokenUriMinter = newTokenUriMinter;

        emit TokenUriMinterUpdated(msg.sender, newTokenUriMinter);
    }         
}