// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IAssemblyPress} from "./interfaces/IAssemblyPress.sol";
import {IZoraNFTCreator} from "./interfaces/IZoraNFTCreator.sol";
import {IAccessControlRegistry} from "onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {OwnableUpgradeable} from "./utils/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ZoraNFTCreatorProxy} from "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import {Publisher} from "./Publisher.sol";
import {PublisherStorage} from "./PublisherStorage.sol";

/**
 * @title AssemblyPress
 * @notice Facilitates deployment of custom ZORA drops with extended functionality
 * @notice not audited use at own risk
 * @author Max Bochman
 *
 */
contract AssemblyPress is
    IAssemblyPress,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable,
    PublisherStorage
{
    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    bytes32 public immutable DEFAULT_ADMIN_ROLE = 0x00;
    address public immutable zoraNFTCreatorProxy;
    Publisher public immutable publisherImplementation;

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    constructor(address _zoraNFTCreatorProxy, Publisher _publisherImplementation) {
        if (_zoraNFTCreatorProxy == address(0) || address(_publisherImplementation) == address(0)) {
            revert CantSet_ZeroAddress();
        }
        zoraNFTCreatorProxy = _zoraNFTCreatorProxy;
        publisherImplementation = _publisherImplementation;

        emit ZoraProxyAddressInitialized(zoraNFTCreatorProxy);
        emit PublisherInitialized(address(publisherImplementation));
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INITIALIZER ||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    function initialize(address _initialOwner) external initializer {
        __Ownable_init(_initialOwner);
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
        address newDropAddress = IZoraNFTCreator(zoraNFTCreatorProxy).setupDropsContract(
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
    // ||| createProvenanceEdition ||||
    // ||||||||||||||||||||||||||||||||

        // MAYBE UNNCESSARY TO GATE THE DERIVATIVE PUBLICATION? NOTHING IS STOPPING ANYONE FROM DOING
        // WHATS HAPPENING BELOW BY INTERACTING WITH THESE CONTRACTS? NOT SURE
        // // check if msg.sender has publication access
        // if (
        //     IAccessControlRegistry(pressInfo[contractAddress].accessControl).getAccessLevel(address(publisherImplementation), msg.sender)
        //         < 1
        // ) {
        //     revert No_PublicationAccess();
        // }    

    // @param contractAddress drop contract from which to make a series of editions
    function createProvenanceEdition(
        address contractAddress,
        uint256 tokenId,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        IERC721Drop.SalesConfiguration memory saleConfig,
        address provenanceRenderer
    ) public nonReentrant returns (address) {

        // get the tokenURI of specific token of the supplied drop
        string memory tokenURI = IMetadataRenderer(contractAddress).tokenURI(tokenId);

        // check if tokenURI of token is blank 
        if (bytes(tokenURI).length == 0) {
            revert CantPromote_BlankArtifact();
        }

        // get the contractURI of the supplied drop
        string memory contractURI = IMetadataRenderer(contractAddress).contractURI();

        // encode the original contractAddress, tokenId, tokenURI, and contractURI to initialize the provenanceRenderer
        bytes memory provenanceRendererInit = abi.encode(contractAddress, tokenId, contractURI, tokenURI);

        // deploy zora collection that pulls info from PublisherStorage
        address provenanceEdition = IZoraNFTCreator(zoraNFTCreatorProxy).setupDropsContract(
            ERC721Drop(payable(contractAddress)).name(), // name
            ERC721Drop(payable(contractAddress)).symbol(), // symbol
            defaultAdmin, // defaultAdmin
            editionSize, // editionSize
            royaltyBPS, // royaltyBPS
            fundsRecipient, // fundsRecipient
            saleConfig, // saleConfig
            IMetadataRenderer(provenanceRenderer), // provenanceRenderer
            provenanceRendererInit // provenanceRendererInit
        );

        return provenanceEdition;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| ADMIN FUNCTIONS ||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Allows only the owner to upgrade the contract
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
