// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ZoraNFTCreatorProxy} from "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {ArtifactMachine} from "./ArtifactMachine.sol";
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
 
    // constructor events
    event ZoraProxyAddressInitialized(address zoraProxyAddress); 
    event ArtifactMachineMetadataRendererInitialized(address artifactMachineMetadataRenderer); 
    event ArtifactMachineInitialized(address artifactMachine); 

    // event called during deploy + configure process
    event MintingModuleInitialized(address zoraDrop, address mintingModule);

    // event called when base impl addresses updated
    event ZoraProxyAddressUpdated(address sender, address newZoraProxyAddress); 
    event ArtifactMachineMetadataRendererUpdated(address sender, address newArtifactMachineMetadataRenderer); 
    event ArtifactMachineUpdated(address sender, address newArtifactMachine);         

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      
    
    bytes32 public immutable DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");
    address public zoraNFTCreatorProxy;
    IMetadataRenderer public artifactMachineMetadataRenderer;
    address public artifactMachine; 
    mapping(address => address) public dropToModule;

    // ||||||||||||||||||||||||||||||||
    // ||| CONSTRUCTOR ||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    constructor(
        address _zoraNFTCreatorProxy, 
        IMetadataRenderer _artifactMachineMetadataRenderer, 
        address _artifactMachine 
    ) {
        zoraNFTCreatorProxy = _zoraNFTCreatorProxy;
        artifactMachineMetadataRenderer = _artifactMachineMetadataRenderer;
        artifactMachine = _artifactMachine;

        emit ZoraProxyAddressInitialized(zoraNFTCreatorProxy);
        emit ArtifactMachineMetadataRendererInitialized(address(artifactMachineMetadataRenderer));
        emit ArtifactMachineInitialized(artifactMachine);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| createArtifactMachine ||||||
    // |||||||||||||||||||||||||||||||| 

    function createArtifactMachine(
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
            artifactMachineMetadataRenderer,
            metadataInitializer           
        );

        // give artifactMachine minter role on zora drop
        ERC721Drop(payable(newDropAddress)).grantRole(MINTER_ROLE, artifactMachine);

        // set mintPricePerToken for zora drop
        ArtifactMachine(artifactMachine).setMintPrice(newDropAddress, mintPricePerToken);

        // grant admin role to desired admin address
        ERC721Drop(payable(newDropAddress)).grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        // revoke admin role from address(this) as it differed from desired admin address
        ERC721Drop(payable(newDropAddress)).revokeRole(DEFAULT_ADMIN_ROLE, address(this));

        // maps newDropAddress => artifactMachine in the dropToModule mapping
        initializeDropToModule(newDropAddress, artifactMachine);

        return newDropAddress;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||

    // initializes the mintingModule address for a given zoraDrop in the dropToModule mapping
    function initializeDropToModule(address zoraDrop, address mintingModule) private {
        dropToModule[zoraDrop] = mintingModule;

        emit MintingModuleInitialized(zoraDrop, mintingModule);
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

    /// @dev updates address value of artifactMachineMetadataRenderer
    /// @param newArtifactMachineMetadataRenderer new artifactMachineMetadataRenderer address
    function setArtifactMachineMetadataRenderer(IMetadataRenderer newArtifactMachineMetadataRenderer) public onlyOwner {

        if (address(newArtifactMachineMetadataRenderer) == address(0)) {
            revert CantSet_ZeroAddress();
        }

        artifactMachineMetadataRenderer = newArtifactMachineMetadataRenderer;

        emit ArtifactMachineMetadataRendererUpdated(msg.sender, address(newArtifactMachineMetadataRenderer));
    }     

    /// @dev updates address value of artifactMachine
    /// @param newArtifactMachine new artifactMachine address
    function setArtifactMachine(address newArtifactMachine) public onlyOwner {

        if (newArtifactMachine == address(0)) {
            revert CantSet_ZeroAddress();
        }

        artifactMachine = newArtifactMachine;

        emit ArtifactMachineUpdated(msg.sender, newArtifactMachine);
    }         
}