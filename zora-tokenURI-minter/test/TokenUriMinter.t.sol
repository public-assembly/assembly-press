// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {TokenUriMinter} from "../src/TokenUriMinter.sol";
import {ERC721DropMinterInterface} from "../src/interfaces/ERC721DropMinterInterface.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {ZoraFeeManager} from "zora-drops-contracts/ZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {TokenUriMetadataRenderer} from "../src/TokenUriMetadataRenderer.sol";
import {ITokenUriMetadataRenderer} from "../src/interfaces/ITokenUriMetadataRenderer.sol";

contract TokenUriMinterTest is DSTest {

    // TokenUriMinter Defaults
    uint256 public mintPrice = 100000000000000; // 0.001 ETH
    address public constant DEFAULT_WILDCARD_ADDRESS = address(0x111);
    address public constant SECONDARY_WILDCARD_ADDRESS = address(0x122);
    string public contractURIString1 = "test_contractURI_1/"; 
    string public contractURIString2 = "test_contractURI_2/"; 
    string public tokenURIString1 = "test_tokenURI_1/";
    string public tokenURIString2 = "test_tokenURI_2/";
    string public tokenURIString3 = "test_tokenURI_3/";

    // ZORA Init Variables
    ERC721Drop zoraNFTBase;
    Vm public constant vm = Vm(HEVM_ADDRESS);    
    TokenUriMetadataRenderer public tokenUriRenderer = new TokenUriMetadataRenderer();
    bytes public tokenUriRendererInit = abi.encode(contractURIString1, DEFAULT_WILDCARD_ADDRESS);
    bytes public tokenUriRendererBadInit = abi.encode("", DEFAULT_WILDCARD_ADDRESS);
    ZoraFeeManager public feeManager;
    FactoryUpgradeGate public factoryUpgradeGate;
    address public constant DEFAULT_OWNER_ADDRESS = address(0x222);
    address public constant DEFAULT_NON_OWNER_ADDRESS = address(0x333);
    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
        payable(address(0x444));
    address payable public constant DEFAULT_ZORA_DAO_ADDRESS =
        payable(address(0x555));
    address public constant UPGRADE_GATE_ADMIN_ADDRESS = address(0x666);
    address public constant marketFilterDAOAddress = address(0x777);
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
            _metadataRenderer: tokenUriRenderer,
            _metadataRendererInit: tokenUriRendererInit,
            _salesConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: 50000000000,
                presaleStart: 0,
                presaleEnd: 0,
                publicSalePrice: 0,
                maxSalePurchasePerAddress: 0,
                presaleMerkleRoot: bytes32(0)
            })
        });

        _;
    }    

    modifier setupZoraNFTBaseBadInit(uint64 editionSize) {
        vm.expectRevert();
        zoraNFTBase.initialize({
            _contractName: "Test NFT",
            _contractSymbol: "TNFT",
            _initialOwner: DEFAULT_OWNER_ADDRESS,
            _fundsRecipient: payable(DEFAULT_FUNDS_RECIPIENT_ADDRESS),
            _editionSize: editionSize,
            _royaltyBPS: 800,
            _metadataRenderer: tokenUriRenderer,
            _metadataRendererInit: tokenUriRendererBadInit,
            _salesConfig: IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: 50000000000,
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
            new ERC721Drop(feeManager, address(0x1234), factoryUpgradeGate, marketFilterDAOAddress)
        );
        address payable newDrop = payable(
            address(new ERC721DropProxy(impl, ""))
        );
        zoraNFTBase = ERC721Drop(newDrop);
    }

    function test_MetadataRendererInit() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString1); 
        assertEq(tokenUriRenderer.wildcardInfo(address(zoraNFTBase)), DEFAULT_WILDCARD_ADDRESS); 
    }

    
    function test_MetadataRendererBadInit() public setupZoraNFTBaseBadInit(15) {
        // expectRevert because empty string passed in as contractURI in bad setup modifer
    }    

    function test_MetadataRendererUpdateTokenURI() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        tokenUriRenderer.updateTokenURI(address(zoraNFTBase), 1, tokenURIString1);
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString1);
    }

    function test_MetadataRendererUpdateContractURI() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        tokenUriRenderer.updateContractURI(address(zoraNFTBase), contractURIString2);
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString2);
    }   

    function test_MetadataRendererUpdateWildcard() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        tokenUriRenderer.updateWildcardAddress(address(zoraNFTBase), SECONDARY_WILDCARD_ADDRESS);
        assertEq(tokenUriRenderer.wildcardInfo(address(zoraNFTBase)), SECONDARY_WILDCARD_ADDRESS);
    }              

    function test_GrantMinterRole() public setupZoraNFTBase(15) {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        TokenUriMinter uriMinter = new TokenUriMinter(
            mintPrice,
            address(tokenUriRenderer)
        );        
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(uriMinter));   
        bool hasMinterRole = zoraNFTBase.hasRole(zoraNFTBase.MINTER_ROLE(), address(uriMinter));
        assertTrue(hasMinterRole);
    }

    function test_Mint() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        // setup array of tokenURIs
        string[] memory testArray = new string[](1);
        testArray[0] = tokenURIString1;
        // deploy TokenUriMinter contract
        TokenUriMinter uriMinter = new TokenUriMinter(
            mintPrice,
            address(tokenUriRenderer)
        );            
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(uriMinter));
        vm.stopPrank();
        address customMintCaller = address(1);
        vm.deal(customMintCaller, 1 ether);
        vm.startPrank(customMintCaller);
        uriMinter.customMint{
            value: mintPrice * testArray.length
        }(address(zoraNFTBase), customMintCaller, testArray);
        assertEq(zoraNFTBase.saleDetails().totalMinted, 1);
        assertEq(customMintCaller.balance, 1 ether - (mintPrice * testArray.length));
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString1); 
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString1);
    }

    function test_BatchMint() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        // setup array of tokenURIs
        string[] memory testArray = new string[](2);
        testArray[0] = tokenURIString1;
        testArray[1] = tokenURIString2;
        // deploy TokenUriMinter contract
        TokenUriMinter uriMinter = new TokenUriMinter(
            mintPrice,
            address(tokenUriRenderer)
        );            
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(uriMinter));
        vm.stopPrank();
        address customMintCaller = address(1);
        vm.deal(customMintCaller, 1 ether);
        vm.startPrank(customMintCaller);
        uriMinter.customMint{
            value: mintPrice * testArray.length
        }(address(zoraNFTBase), customMintCaller, testArray);
        assertEq(zoraNFTBase.saleDetails().totalMinted, 2);
        assertEq(customMintCaller.balance, 1 ether - (mintPrice * testArray.length));
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString1); 
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString1);
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 2), tokenURIString2);
    }    

    function test_updateTokenURIPostMint() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        // setup array of tokenURIs
        string[] memory testArray = new string[](1);
        testArray[0] = tokenURIString1;
        // deploy TokenUriMinter contract
        TokenUriMinter uriMinter = new TokenUriMinter(
            mintPrice,
            address(tokenUriRenderer)
        );          
        zoraNFTBase.grantRole(zoraNFTBase.MINTER_ROLE(), address(uriMinter));
        vm.stopPrank();
        address customMintCaller = address(1);
        vm.deal(customMintCaller, 1 ether);
        vm.startPrank(customMintCaller);
        uriMinter.customMint{
            value: mintPrice * testArray.length
        }(address(zoraNFTBase), customMintCaller, testArray);
        assertEq(zoraNFTBase.saleDetails().totalMinted, 1);
        assertEq(customMintCaller.balance, 1 ether - (mintPrice));
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString1); 
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString1);
        vm.stopPrank();
        
        // example of non zora drop admin, token owner, or jen stark
        //      being barred from updating tokenURI post mint
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        vm.expectRevert();
        tokenUriRenderer.updateTokenURI(address(zoraNFTBase), 1, tokenURIString2);
        vm.stopPrank();

        // example of token owner being able to change tokenURI
        vm.startPrank(customMintCaller);
        tokenUriRenderer.updateTokenURI(address(zoraNFTBase), 1, tokenURIString2);
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString2);
        vm.stopPrank();

        // example of zora drop admin being able to change tokenURI
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        tokenUriRenderer.updateTokenURI(address(zoraNFTBase), 1, tokenURIString1);
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString1);
        vm.stopPrank();         

        // example of wildcardAddress being able to change tokenURI
        vm.startPrank(DEFAULT_WILDCARD_ADDRESS);
        tokenUriRenderer.updateTokenURI(address(zoraNFTBase), 1, tokenURIString3);
        assertEq(tokenUriRenderer.tokenURIInfo(address(zoraNFTBase), 1), tokenURIString3);
        vm.stopPrank();        
    }    

    function test_updateContractURIPostDeploy() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString1); 
        vm.stopPrank();
        
        // example of non zora drop admin being barred from updating contractURI post deploy
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        vm.expectRevert();
        tokenUriRenderer.updateContractURI(address(zoraNFTBase), contractURIString2);
        vm.stopPrank();
        
        // example of zora drop admin being able to update contractURI post deploy        
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        tokenUriRenderer.updateContractURI(address(zoraNFTBase), contractURIString2);
        assertEq(tokenUriRenderer.contractURIInfo(address(zoraNFTBase)), contractURIString2);
    }    

    function test_updateWildcardAddressPostDeploy() public setupZoraNFTBase(15) { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        assertEq(tokenUriRenderer.wildcardInfo(address(zoraNFTBase)), DEFAULT_WILDCARD_ADDRESS); 
        vm.stopPrank();
        
        // example of non zora drop admin being barred from updating wildcardAddress post deploy
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        vm.expectRevert();
        tokenUriRenderer.updateWildcardAddress(address(zoraNFTBase), SECONDARY_WILDCARD_ADDRESS);
        vm.stopPrank();
        
        // example of zora drop admin being able to update wildcardAddress post deploy        
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        tokenUriRenderer.updateWildcardAddress(address(zoraNFTBase), SECONDARY_WILDCARD_ADDRESS);
        assertEq(tokenUriRenderer.wildcardInfo(address(zoraNFTBase)), SECONDARY_WILDCARD_ADDRESS);
        vm.stopPrank();

        // example of wildcardAddress being able to update wildcardAddress post deploy        
        vm.startPrank(SECONDARY_WILDCARD_ADDRESS);
        tokenUriRenderer.updateWildcardAddress(address(zoraNFTBase), DEFAULT_OWNER_ADDRESS);
        assertEq(tokenUriRenderer.wildcardInfo(address(zoraNFTBase)), DEFAULT_OWNER_ADDRESS);
        vm.stopPrank();        
    }     
}