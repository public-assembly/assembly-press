// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {CustomPricingMinter} from "../src/CustomPricingMinter.sol";
import {ERC721DropMinterInterface} from "../src/ERC721DropMinterInterface.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {ZoraFeeManager} from "zora-drops-contracts/ZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {DummyMetadataRenderer} from "../src/utils/DummyMetadataRenderer.sol";
import {MockUser} from "../src/utils/MockUser.sol";

contract CustomPricingMinterTest is DSTest {

    // CustomPricingMinter Defaults
    uint256 nonBundlePrice = 1000000000000000; // 0.01 ETH
    uint256 bundlePrice = 5000000000000000; // 0.005 ETH
    uint256 defaultNonBundleQuantity = 1;
    uint256 defaultBundleQuantity = 10;

    // ZORA Init Variables
    ERC721Drop zoraNFTBase;
    MockUser mockUser;
    Vm public constant vm = Vm(HEVM_ADDRESS);
    DummyMetadataRenderer public dummyRenderer = new DummyMetadataRenderer();
    ZoraFeeManager public feeManager;
    FactoryUpgradeGate public factoryUpgradeGate;
    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
        payable(address(0x21303));
    address payable public constant DEFAULT_ZORA_DAO_ADDRESS =
        payable(address(0x999));
    address public constant UPGRADE_GATE_ADMIN_ADDRESS = address(0x942924224);
    address public constant mediaContract = address(0x123456);
    address public impl;    

    struct Configuration {
        IMetadataRenderer metadataRenderer;
        uint64 editionSize;
        uint16 royaltyBPS;
        address payable fundsRecipient;
    }

    modifier setupZoraNFTBase(uint64 editionSize) {
        zoraNFTBase.initialize({
            _contractName: "Test NFT",
            _contractSymbol: "TNFT",
            _initialOwner: DEFAULT_OWNER_ADDRESS,
            _fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
            _editionSize: editionSize,
            _royaltyBPS: 800,
            _metadataRenderer: dummyRenderer,
            _metadataRendererInit: "",
            _salesConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: 0,
                presaleStart: 0,
                presaleEnd: 0,
                publicSalePrice: 0,
                maxSalePurchasePerAddress: 0,
                presaleMerkleRoot: bytes32(0)
            })
        });

        _;
    }    

    // Sets up ZORA Drop architecture
    function setUp() public {
        vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
        feeManager = new ZoraFeeManager(500, DEFAULT_ZORA_DAO_ADDRESS);
        factoryUpgradeGate = new FactoryUpgradeGate(UPGRADE_GATE_ADMIN_ADDRESS);
        vm.prank(DEFAULT_ZORA_DAO_ADDRESS);
        impl = address(
            new ERC721Drop(feeManager, address(0x1234), factoryUpgradeGate)
        );
        address payable newDrop = payable(
            address(new ERC721DropProxy(impl, ""))
        );
        zoraNFTBase = ERC721Drop(newDrop);
    }

    function test_GrantMinterRole() public setupZoraNFTBase(15) {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));   
        bool hasMinterRole = zoraNFTBase.hasRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        assertTrue(hasMinterRole);
    }

    function test_NonBundleMint() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();
        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: nonBundlePrice * defaultNonBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultNonBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultNonBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - (nonBundlePrice * defaultNonBundleQuantity));
    }

    function test_BundleMint() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();
        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity));
    }    

    function test_setBundlePrice() public setupZoraNFTBase(21) { 

        uint256 newBundlePrice = 6000000000000000; // 0.006 ETH

        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();
        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity));
        vm.stopPrank();
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        vm.deal(DEFAULT_OWNER_ADDRESS, 1 ether);
        minterContract.setBundlePricePerToken(newBundlePrice); 
        assertEq(minterContract.bundlePricePerToken(), newBundlePrice);            
        vm.expectRevert();
        // flexibleMint should fail because it is passing in msg.value based on old bundlePrice
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        vm.stopPrank();
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: newBundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, (defaultBundleQuantity * 2));
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity) - (newBundlePrice * defaultBundleQuantity));
    }        

    function test_setNonBundlePrice() public setupZoraNFTBase(21) { 

        uint256 newNonBundlePrice = 2000000000000000; // 0.02 ETH

        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();
        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity));
        vm.stopPrank();
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        vm.deal(DEFAULT_OWNER_ADDRESS, 1 ether);
        minterContract.setBundlePricePerToken(newNonBundlePrice); 
        assertEq(minterContract.bundlePricePerToken(), newNonBundlePrice);            
        vm.expectRevert();
        // flexibleMint should fail because it is passing in msg.value based on old nonBundlePrice
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        vm.stopPrank();
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: newNonBundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, (defaultBundleQuantity * 2));
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity) - (newNonBundlePrice * defaultBundleQuantity));
    }            

    function test_setBundleQuantity() public setupZoraNFTBase(31) { 

        uint256 newBundleQuantity = 11;

        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();
        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity));
        vm.stopPrank();
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        vm.deal(DEFAULT_OWNER_ADDRESS, 1 ether);
        minterContract.setBundleQuantity(newBundleQuantity); 
        assertEq(minterContract.bundleQuantity(), newBundleQuantity);         
        vm.stopPrank();
        vm.startPrank(flexibleMintCaller);
        vm.expectRevert();
        // flexibleMint should fail because passing in bundlePrice for what is now a quantity below new bundleQuantity
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity); 
        minterContract.flexibleMint{
            value:  nonBundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);    
        assertEq(zoraNFTBase.saleDetails().totalMinted, (defaultBundleQuantity * 2));
        assertEq(flexibleMintCaller.balance, 1 ether - (bundlePrice * defaultBundleQuantity) - (nonBundlePrice * defaultBundleQuantity));        
        minterContract.flexibleMint{
            value:  bundlePrice * newBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, newBundleQuantity);    
        assertEq(zoraNFTBase.saleDetails().totalMinted, ((defaultBundleQuantity * 2) + newBundleQuantity));
        assertEq(flexibleMintCaller.balance, 1 ether - 
            (bundlePrice * defaultBundleQuantity) - (nonBundlePrice * defaultBundleQuantity) - (bundlePrice * newBundleQuantity));                
    }

    function test_WithdrawFunds() public setupZoraNFTBase(15) {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        CustomPricingMinter minterContract = new CustomPricingMinter(
            nonBundlePrice,
            bundlePrice,
            defaultBundleQuantity
        );
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(minterContract));
        vm.stopPrank();

        uint256 initialFunds = address(zoraNFTBase).balance;

        address flexibleMintCaller = address(1);
        vm.deal(flexibleMintCaller, 1 ether);
        vm.startPrank(flexibleMintCaller);
        minterContract.flexibleMint{
            value: bundlePrice * defaultBundleQuantity 
        }(address(zoraNFTBase), flexibleMintCaller, defaultBundleQuantity);
        assertEq(zoraNFTBase.saleDetails().totalMinted, defaultBundleQuantity);
        uint256 mintedCost = (bundlePrice * defaultBundleQuantity);
        assertEq(flexibleMintCaller.balance, 1 ether - mintedCost);
        vm.stopPrank();

        assertEq(address(zoraNFTBase).balance, initialFunds + mintedCost);
    }
}