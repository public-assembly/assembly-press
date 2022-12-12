// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {ZoraFeeManager} from "zora-drops-contracts/ZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import "zora-drops-contracts/ZoraNFTCreatorV1.sol";

import {AssemblyPress} from "../src/AssemblyPress.sol";
import {IPublisher} from "../src/interfaces/IPublisher.sol";
import {Publisher} from "../src/Publisher.sol";
import {PublisherStorage} from "../src/PublisherStorage.sol";
import {DefaultMetadataDecoder} from "../src/DefaultMetadataDecoder.sol";
import {IAccessControlRegistry} from "onchain/interfaces/IAccessControlRegistry.sol";
import {OnlyAdminAccessControl} from "onchain/OnlyAdminAccessControl.sol";

contract AssemblyPressArchitectureTest is DSTest {

    // VM init + Base Defaults
    Vm public constant vm = Vm(HEVM_ADDRESS);
    // uint256 public mintPrice = 100000000000000; // 0.001 ETH
    uint256 public mintPrice = 0;
    string public contractURIString1 = "test_contractURI_1/";
    string public tokenURIString1 = "test_tokenURI_1/";
    bytes public tokenURIString1_encoded = abi.encode(tokenURIString1);
    string public tokenURIString2 = "test_tokenURI_2/";
    bytes public tokenURIString2_encoded = abi.encode(tokenURIString2);    
    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);

    // AssemblyPress architecture set up
    AssemblyPress public assemblyPress;
    Publisher public publisher;
    DefaultMetadataDecoder public defaultMetaDecoder;
    OnlyAdminAccessControl public onlyAdminAC;
    bytes public accessControlInit = abi.encode(DEFAULT_OWNER_ADDRESS);

    // ZORA Init Variables
    
    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
        payable(address(0x21303));
    address payable public constant DEFAULT_ZORA_DAO_ADDRESS =
        payable(address(0x999));
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
        creator = ZoraNFTCreatorV1(
            address(new ZoraNFTCreatorProxy(address(impl), ""))
        );
        creator.initialize();

        // deploy AssemblyPress infra
        publisher = new Publisher();
        defaultMetaDecoder = new DefaultMetadataDecoder();
        onlyAdminAC = new OnlyAdminAccessControl();
        assemblyPress = new AssemblyPress(
            address(creator),
            address(editionMetadataRenderer),
            publisher
        );
    }

    function test_CreatePublication() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        address zoraDrop = assemblyPress.createPublication({
            name: "TestDrop",
            symbol: "TD",
            defaultAdmin: DEFAULT_OWNER_ADDRESS,
            editionSize: 18446744073709551615,
            royaltyBPS: 1000,
            fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
            saleConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0, 
                publicSaleEnd: 0, 
                presaleStart: 0, 
                presaleEnd: 0, 
                publicSalePrice: 0, 
                maxSalePurchasePerAddress: 0, 
                presaleMerkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000
            }),
            contractURI: contractURIString1,
            accessControl: address(onlyAdminAC),
            accessControlInit: accessControlInit,
            mintPricePerToken: mintPrice
        });
        ERC721Drop pubChannel = ERC721Drop(payable(zoraDrop));        
        assertEq(onlyAdminAC.getAccessLevel(address(publisher), DEFAULT_OWNER_ADDRESS), 3);
        assertEq(pubChannel.contractURI(), contractURIString1);
    }

    function test_publish() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        address zoraDrop = assemblyPress.createPublication({
            name: "TestDrop",
            symbol: "TD",
            defaultAdmin: DEFAULT_OWNER_ADDRESS,
            editionSize: 18446744073709551615,
            royaltyBPS: 1000,
            fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
            saleConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0, 
                publicSaleEnd: 0, 
                presaleStart: 0, 
                presaleEnd: 0, 
                publicSalePrice: 0, 
                maxSalePurchasePerAddress: 0, 
                presaleMerkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000
            }),
            contractURI: contractURIString1,
            accessControl: address(onlyAdminAC),
            accessControlInit: accessControlInit,
            mintPricePerToken: mintPrice
        });
        ERC721Drop pubChannel = ERC721Drop(payable(zoraDrop));     
        IPublisher.ArtifactDetails[] memory artifacts = new IPublisher.ArtifactDetails[](1);
        artifacts[0].artifactRenderer = address(defaultMetaDecoder);
        artifacts[0].artifactMetadata = tokenURIString1_encoded;
        publisher.publish(
            zoraDrop,
            DEFAULT_OWNER_ADDRESS,
            artifacts
        );
        assertEq(pubChannel.saleDetails().totalMinted, 1);
        assertEq(pubChannel.tokenURI(1), tokenURIString1);

        // FIGURE OUT HOW TO TEST THE INDIVIDUAL VALUES FROM publisher.artifactInfo()
        // want to check if the address artifactRenderer + bytes memory artifactMetadata are correct
        // console.logBytes(tokenURIString1_encoded);
    }

    function test_edit() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        address zoraDrop = assemblyPress.createPublication({
            name: "TestDrop",
            symbol: "TD",
            defaultAdmin: DEFAULT_OWNER_ADDRESS,
            editionSize: 18446744073709551615,
            royaltyBPS: 1000,
            fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
            saleConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0, 
                publicSaleEnd: 0, 
                presaleStart: 0, 
                presaleEnd: 0, 
                publicSalePrice: 0, 
                maxSalePurchasePerAddress: 0, 
                presaleMerkleRoot: 0x0000000000000000000000000000000000000000000000000000000000000000
            }),
            contractURI: contractURIString1,
            accessControl: address(onlyAdminAC),
            accessControlInit: accessControlInit,
            mintPricePerToken: mintPrice
        });
        ERC721Drop pubChannel = ERC721Drop(payable(zoraDrop));     
        IPublisher.ArtifactDetails[] memory artifacts_1 = new IPublisher.ArtifactDetails[](1);
        artifacts_1[0].artifactRenderer = address(defaultMetaDecoder);
        artifacts_1[0].artifactMetadata = tokenURIString1_encoded;
        publisher.publish(
            zoraDrop,
            DEFAULT_OWNER_ADDRESS,
            artifacts_1
        );
        assertEq(pubChannel.saleDetails().totalMinted, 1);
        assertEq(pubChannel.tokenURI(1), tokenURIString1);    

        IPublisher.ArtifactDetails[] memory artifacts_2 = new IPublisher.ArtifactDetails[](1);
        artifacts_2[0].artifactRenderer = address(defaultMetaDecoder);
        artifacts_2[0].artifactMetadata = tokenURIString2_encoded;        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        publisher.edit(
            zoraDrop,
            tokenIds,
            artifacts_2
        );
    }
}