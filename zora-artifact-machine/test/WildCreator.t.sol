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
import {WildMachine} from "../src/WildMachine.sol";
import {WildRenderer} from "../src/WildRenderer.sol";
import {WildCreator} from "../src/WildCreator.sol";
import {ERC721DropMinterInterface} from "../src/interfaces/ERC721DropMinterInterface.sol";
import {OnlyAdminAccessControl} from "onchain/OnlyAdminAccessControl.sol";

contract WildCreatorTest is DSTest {

    // VM init + Base Defaults
    Vm public constant vm = Vm(HEVM_ADDRESS);
    uint256 public mintPrice = 100000000000000; // 0.001 ETH
    address public constant DEFAULT_OWNER_ADDRESS = address(0x1111);
    string public contractURIString1 = "test_contractURI_1/";
    string public tokenURIString1 = "test_tokenURI_1/";

    // WildMachine architecture set up
    OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();
    WildRenderer public wildRenderer = new WildRenderer();
    bytes public accessControlInit = abi.encode(DEFAULT_OWNER_ADDRESS);
    WildMachine wildMachine = new WildMachine(
        address(wildRenderer)
    );

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
    }    

    function test_DeployAndConfigureUriDrop() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);   
        vm.deal(DEFAULT_OWNER_ADDRESS, 1 ether); 
        // deploy PACreatorV1        
        WildCreator wildCreator = new WildCreator(
            address(creator),
            wildRenderer,
            address(wildMachine)
        );
        // deploy + configure a ZORA drop w/ the ArtifactMachine architecture
        address configuredDrop = wildCreator.createArtifactMachine({
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
            accessControl: address(adminAccessControl),
            accessControlInit: accessControlInit,
            mintPricePerToken: mintPrice  
        });
        ERC721Drop drop = ERC721Drop(payable(configuredDrop));
        // set up metadata for mint
        string[] memory testArray = new string[](1);
        testArray[0] = tokenURIString1;        
        // test that minting works
        wildMachine.createArtifact{
            value: mintPrice * testArray.length
        }(address(drop), DEFAULT_OWNER_ADDRESS, DEFAULT_OWNER_ADDRESS, testArray);
        assertEq(drop.saleDetails().totalMinted, 1);
        assertEq(DEFAULT_OWNER_ADDRESS.balance, 1 ether - (mintPrice * testArray.length));
        assertEq(wildRenderer.contractURIInfo(address(drop)), contractURIString1); 
        assertEq(wildRenderer.artifactInfo(address(drop), 1), tokenURIString1);        
    }
}