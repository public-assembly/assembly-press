// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";

import {EditionMetadataRenderer} from "zora-drops-contracts/metadata/EditionMetadataRenderer.sol";
import {DropMetadataRenderer} from "zora-drops-contracts/metadata/DropMetadataRenderer.sol";

import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {ZoraFeeManager} from "zora-drops-contracts/ZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {ZoraNFTCreatorProxy} from "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import {ZoraNFTCreatorV1} from "zora-drops-contracts/ZoraNFTCreatorV1.sol";

import {AssemblyPress} from "../src/AssemblyPress.sol";
import {IPublisher} from "../src/interfaces/IPublisher.sol";
import {Publisher} from "../src/Publisher.sol";
import {PublisherStorage} from "../src/PublisherStorage.sol";
import {DefaultMetadataDecoder} from "../src/DefaultMetadataDecoder.sol";
import {IAccessControlRegistry} from "onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";
import {OnlyAdminAccessControl} from "onchain/remote-access-control/src/OnlyAdminAccessControl.sol";

contract DropConfig is Test {
    // AssemblyPress architecture set up
    AssemblyPress public assemblyPress;
    Publisher public publisher;
    DefaultMetadataDecoder public defaultMetaDecoder;
    OnlyAdminAccessControl public onlyAdminAC;
    bytes public accessControlInit = abi.encode(DEFAULT_OWNER_ADDRESS);
    bytes public accessControlInit2 = abi.encode(DEFAULT_NON_OWNER_ADDRESS);
    IPublisher.PressDetails pressDetails;

    // Zora drop initialization variables
    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
    address public constant DEFAULT_NON_OWNER_ADDRESS = address(0x666);
    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS = payable(address(0x21303));
    address payable public constant DEFAULT_ZORA_DAO_ADDRESS = payable(address(0x999));
    ERC721Drop public dropImpl;
    ZoraNFTCreatorV1 public creator;
    EditionMetadataRenderer public editionMetadataRenderer;
    DropMetadataRenderer public dropMetadataRenderer;

    function setUp() public {
        vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
        ZoraFeeManager feeManager = new ZoraFeeManager(
            500,
            DEFAULT_ZORA_DAO_ADDRESS
        );
        vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
        dropImpl = new ERC721Drop(
            feeManager,
            address(1234),
            FactoryUpgradeGate(address(0)),
            address(0)
        );
        editionMetadataRenderer = new EditionMetadataRenderer();
        dropMetadataRenderer = new DropMetadataRenderer();
        ZoraNFTCreatorV1 impl = new ZoraNFTCreatorV1(
            address(dropImpl),
            editionMetadataRenderer,
            dropMetadataRenderer
        );
        creator = ZoraNFTCreatorV1(address(new ZoraNFTCreatorProxy(address(impl), "")));
        creator.initialize();

        // AssemblyPress architecture deploy
        publisher = new Publisher();
        defaultMetaDecoder = new DefaultMetadataDecoder();
        onlyAdminAC = new OnlyAdminAccessControl();

        // Deploys an unproxied, unowned, and uninitialized factory
        assemblyPress = new AssemblyPress(
            address(creator),
            address(editionMetadataRenderer),
            publisher
        );
    }
}
