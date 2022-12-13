// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IZoraCreatorInterface} from "./interfaces/IZoraCreatorInterface.sol";
import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ZoraNFTCreatorProxy} from "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import {Publisher} from "./Publisher.sol";
import {PublisherStorage} from "./Publisher.sol";

/**
 * @title AssemblyPress
 * @notice Facilitates deployment of custom ZORA drops with extended functionality
 * @notice not audited use at own risk
 * @author Max Bochman
 *
 */
contract AssemblyPress is OwnableUpgradeable, ReentrancyGuardUpgradeable, PublisherStorage {
    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // constructor events
    event ZoraProxyAddressInitialized(address zoraProxyAddress);
    event ZEditionMetadataRendererInitialized(address zoraProxyAddress);
    event PublisherInitialized(address publisherAddress);

    // event called when base impl addresses updated
    event ZoraProxyAddressUpdated(address sender, address newZoraProxyAddress);
    event ZEditionMetadataRendererUpdated(address sender, address newZEditionMetadataRendererAddress);
    event PublisherUpdated(address sender, address newPublisherAddress);

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    bytes32 public immutable DEFAULT_ADMIN_ROLE = 0x00;
    address public zoraNFTCreatorProxy;
    address public zEditionMetadataRenderer;
    Publisher public publisherImplementation;

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    function initialize(address _initialOwner, address _zoraNFTCreatorProxy, address _zEditionMetadataRenderer, Publisher _publisherImplementation)
        initializer external
    {
        __Ownable_init(_initialOwner);

        zoraNFTCreatorProxy = _zoraNFTCreatorProxy;
        zEditionMetadataRenderer = _zEditionMetadataRenderer;
        publisherImplementation = _publisherImplementation;

        emit ZoraProxyAddressInitialized(zoraNFTCreatorProxy);
        emit ZEditionMetadataRendererInitialized(zEditionMetadataRenderer);
        emit PublisherInitialized(address(publisherImplementation));
    }

    // ||||||||||||||||||||||||||||||||
    // ||| createPublication ||||||||||
    // ||||||||||||||||||||||||||||||||

    function createPublication(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory contractURI,
        address accessControl,
        bytes memory accessControlInit,
        uint256 mintPricePerToken
    ) public nonReentrant returns (address) {
        // encode contractURI + mintPricePerToken + accessControl + accessControl init to pass into ArtifactMachineRegistry
        bytes memory publisherInitializer = abi.encode(contractURI, mintPricePerToken, accessControl, accessControlInit);

        // deploy zora collection - defaultAdmin must be address(this) here but will be updated later
        address newDropAddress = IZoraCreatorInterface(zoraNFTCreatorProxy).setupDropsContract(
            name,
            symbol,
            address(this),
            editionSize,
            royaltyBPS,
            fundsRecipient,
            saleConfig,
            publisherImplementation,
            publisherInitializer
        );

        // give publisherImplementation minter role on zora drop
        ERC721Drop(payable(newDropAddress)).grantRole(MINTER_ROLE, address(publisherImplementation));

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

    /// @dev updates address value of publisherImplementation
    /// @param newPublisherImplementation new newPublisherImplementation address
    function setPublisher(Publisher newPublisherImplementation) public onlyOwner {
        if (address(newPublisherImplementation) == address(0)) {
            revert CantSet_ZeroAddress();
        }

        publisherImplementation = newPublisherImplementation;

        emit PublisherUpdated(msg.sender, address(newPublisherImplementation));
    }

    /// @dev updates address value of zEditionMetadataRenderer
    /// @param newZEditionMetadataRenderer new ZEditionMetadataRenderer address
    function setzEditionMetadataRenderer(address newZEditionMetadataRenderer) public onlyOwner {
        if (newZEditionMetadataRenderer == address(0)) {
            revert CantSet_ZeroAddress();
        }

        zEditionMetadataRenderer = newZEditionMetadataRenderer;

        emit ZEditionMetadataRendererUpdated(msg.sender, newZEditionMetadataRenderer);
    }
}

// function promoteToEdition(
//     address zoraDrop,
//     uint256 tokenId,
//     string memory name,
//     string memory symbol,
//     uint64 editionSize,
//     uint16 royaltyBPS,
//     address payable fundsRecipient,
//     address defaultAdmin,
//     IERC721Drop.SalesConfiguration memory saleConfig,
//     string memory description
// ) public nonReentrant returns (address) {

//     // check if msg.sender has publication access
//     if (IAccessControlRegistry(dropAccessControl[zoraDrop]).getAccessLevel(address(this), msg.sender) < 1) {
//         revert No_PublicationAccess();
//     }

//     // deploy zora collection that pulls info from PublisherStorage
//     address newDropAddress = IZoraCreatorInterface(zoraNFTCreatorProxy).createEdition(
//         name,
//         symbol,
//         editionSize,
//         royaltyBPS,
//         fundsRecipient,
//         defaultAdmin,
//         saleConfig,
//         description,
//         zoraDrop.tokenURI(tokenId),
//         zoraDrop.tokenURI(tokenId)
//     );

//     return newDropAddress;
// }
