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
import {ArtifactMachine} from "../src/ArtifactMachine.sol";
import {ArtifactMachineMetadataRenderer} from "../src/ArtifactMachineMetadataRenderer.sol";
import {PACreatorV1} from "../src/PACreatorV1.sol";
import {ERC721DropMinterInterface} from "../src/interfaces/ERC721DropMinterInterface.sol";

contract PACreatorV1Test is DSTest {

    // VM init + Base Defaults
    Vm public constant vm = Vm(HEVM_ADDRESS);
    uint256 public mintPrice = 100000000000000; // 0.001 ETH
    address public constant DEFAULT_WILDCARD_ADDRESS = address(0x111);
    string public contractURIString1 = "test_contractURI_1/";
    string public tokenURIString1 = "test_tokenURI_1/";

    // ArtifactMachine architecture set up
    ArtifactMachineMetadataRenderer public artMachRenderer = new ArtifactMachineMetadataRenderer();
    bytes public artMachRendererInit = abi.encode(contractURIString1, DEFAULT_WILDCARD_ADDRESS);
    ArtifactMachine artifactMachine = new ArtifactMachine(
        address(artMachRenderer)
    );

    // ZORA Init Variables
    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
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
    }    

    function test_DeployAndConfigureUriDrop() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        // deploy PACreatorV1        
        PACreatorV1 paCreator = new PACreatorV1(
            address(creator),
            artMachRenderer,
            address(artifactMachine)
        );
        // deploy + configure a ZORA drop w/ the ArtifactMachine architecture
        address configuredDrop = paCreator.createArtifactMachine({
            name: "Test NFT",
            symbol: "TNFT",
            defaultAdmin: DEFAULT_OWNER_ADDRESS,
            editionSize: 1000,
            royaltyBPS: 1000,
            fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
            saleConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: 0,
                presaleStart: 0,
                presaleEnd: 0,
                publicSalePrice: 0,
                maxSalePurchasePerAddress: 0,
                presaleMerkleRoot: bytes32(0)
            }),
            contractURI: contractURIString1,
            wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
            mintPricePerToken: mintPrice   
        });
        ERC721Drop drop = ERC721Drop(payable(configuredDrop));
        vm.stopPrank();
        address createArtifactCaller = address(1);
        vm.deal(createArtifactCaller, 1 ether);
        vm.startPrank(createArtifactCaller);
        // set up metadata for mint
        string[] memory testArray = new string[](1);
        testArray[0] = tokenURIString1;        
        // test that minting works
        artifactMachine.createArtifact{
            value: mintPrice * testArray.length
        }(address(drop), createArtifactCaller, testArray);
        assertEq(drop.saleDetails().totalMinted, 1);
        assertEq(createArtifactCaller.balance, 1 ether - (mintPrice * testArray.length));
        assertEq(artMachRenderer.contractURIInfo(address(drop)), contractURIString1); 
        assertEq(artMachRenderer.artifactInfo(address(drop), 1), tokenURIString1);        
    }
}