// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ZoraFeeManager} from "zora-drops-contracts/ZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import "zora-drops-contracts/ZoraNFTCreatorProxy.sol";
import "zora-drops-contracts/ZoraNFTCreatorV1.sol";
import {WildMachine} from "../src/WildMachine.sol";
import {WildRenderer} from "../src/WildRenderer.sol";
import {ERC721DropMinterInterface} from "../src/interfaces/ERC721DropMinterInterface.sol";
import {WildCreator} from "../src/WildCreator.sol";
import {OnlyAdminAccessControl} from "onchain/OnlyAdminAccessControl.sol";

contract WildMachineTest is DSTest {

    // VM init + Base Defaults
    Vm public constant vm = Vm(HEVM_ADDRESS);        
    uint256 public mintPrice = 100000000000000; // 0.001 ETH
    address public constant DEFAULT_WILDCARD_ADDRESS = address(0x111);
    address public constant SECONDARY_WILDCARD_ADDRESS = address(0x122);
    string public contractURIString1 = "test_contractURI_1/"; 
    string public contractURIString2 = "test_contractURI_2/"; 
    string public tokenURIString1 = "test_tokenURI_1/";
    string public tokenURIString2 = "test_tokenURI_2/";
    string public tokenURIString3 = "test_tokenURI_3/";

    // TokenURI Init
    OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();
    WildRenderer public wildRenderer = new WildRenderer();
    bytes public accessControlInit = abi.encode(DEFAULT_OWNER_ADDRESS);
    // bytes public wildRendererInit = abi.encode(contractURIString1, DEFAULT_WILDCARD_ADDRESS);
    // bytes public wildRendererBadInit = abi.encode("", DEFAULT_WILDCARD_ADDRESS);
    WildMachine wildMachine = new WildMachine(
        address(wildRenderer)
    );
    WildCreator wCreator;

    // ZORA Init
    address public constant DEFAULT_OWNER_ADDRESS = address(0x23499);
    address public constant DEFAULT_NON_OWNER_ADDRESS = address(0x478);
    address payable public constant DEFAULT_FUNDS_RECIPIENT_ADDRESS =
        payable(address(0x21303));
    address payable public constant DEFAULT_ZORA_DAO_ADDRESS =
        payable(address(0x999));
    ERC721Drop public dropImpl;
    ZoraNFTCreatorV1 public creator;
    EditionMetadataRenderer public editionMetadataRenderer;
    DropMetadataRenderer public dropMetadataRenderer;

    // Sets up ZORA Drop + wCreator architecture
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

    function test_MetadataRendererInit() public  { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);   
        WildCreator wCreator = new WildCreator(
            address(creator),
            wildRenderer,
            address(wildMachine)
        );
        //  deploy + configure ZORA drop with WildMachine architecture
        address configuredDrop = wCreator.createArtifactMachine({
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
        assertEq(wildRenderer.contractURIInfo(address(configuredDrop)), contractURIString1); 
        assertEq(wildRenderer.dropToAccessControl(address(configuredDrop)), address(adminAccessControl)); 
    }
    
    function test_MetadataRendererBadInit() public  {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);        
        WildCreator wCreator = new WildCreator(
            address(creator),
            wildRenderer,
            address(wildMachine)
        );
        // expect revert because empty string being set as contractURI
        vm.expectRevert();         
        //  deploy + configure ZORA drop with WildMachine architecture
        address configuredDrop = wCreator.createArtifactMachine({
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
            contractURI: "",
            accessControl: address(adminAccessControl),
            accessControlInit: accessControlInit,
            mintPricePerToken: mintPrice 
        });        
    }    

    function test_MetadataRendererUpdateContractURI() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);    
        WildCreator wCreator = new WildCreator(
            address(creator),
            wildRenderer,
            address(wildMachine)
        );
        //  deploy + configure ZORA drop with WildMachine architecture
        address configuredDrop = wCreator.createArtifactMachine({
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
        wildRenderer.updateContractURI(address(configuredDrop), contractURIString2);
        assertEq(wildRenderer.contractURIInfo(address(configuredDrop)), contractURIString2);
    }    

    // function test_CantUpdateArtifactUntilItsMinted() public  { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);    
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         accessControl: address(adminAccessControl),
    //         accessControlInit: accessControlInit,
    //         mintPricePerToken: mintPrice 
    //     });        
    //     vm.expectRevert();
    //     wildRenderer.updateArtifact(address(configuredDrop), 1, DEFAULT_OWNER_ADDRESS, tokenURIString1);
    // }                 

    function test_Mint() public { 
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        vm.deal(DEFAULT_OWNER_ADDRESS, 1 ether);
        // setup array of tokenURIs
        string[] memory testArray = new string[](1);
        testArray[0] = tokenURIString1;
        // deploy wCreator Contract
        WildCreator wCreator = new WildCreator(
            address(creator),
            wildRenderer,
            address(wildMachine)
        );
        //  deploy + configure ZORA drop with WildMachine architecture
        address configuredDrop = wCreator.createArtifactMachine({
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
        wildMachine.createArtifact{
            value: mintPrice * testArray.length
        }(address(configuredDrop), DEFAULT_OWNER_ADDRESS, DEFAULT_OWNER_ADDRESS, testArray);
        assertEq(ERC721Drop(payable(configuredDrop)).saleDetails().totalMinted, 1);
        assertEq(DEFAULT_OWNER_ADDRESS.balance, 1 ether - (mintPrice * testArray.length));
        assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString1); 
        assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString1);
    } 

    // function test_BatchMint() public { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     // setup array of tokenURIs
    //     string[] memory testArray = new string[](2);
    //     testArray[0] = tokenURIString1;
    //     testArray[1] = tokenURIString2;
    //     // deploy wCreator Contract
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
    //         mintPricePerToken: mintPrice   
    //     });            
    //     vm.stopPrank();
    //     address createArtifactCaller = address(1);
    //     vm.deal(createArtifactCaller, 1 ether);
    //     vm.startPrank(createArtifactCaller);
    //     wildMachine.createArtifact{
    //         value: mintPrice * testArray.length
    //     }(configuredDrop, createArtifactCaller, testArray);
    //     assertEq(ERC721Drop(payable(configuredDrop)).saleDetails().totalMinted, 2);
    //     assertEq(createArtifactCaller.balance, 1 ether - (mintPrice * testArray.length));
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString1); 
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString1);
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 2), tokenURIString2);
    // }    

    // function test_updateArtifactPostMint() public { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     // setup array of tokenURIs
    //     string[] memory testArray = new string[](1);
    //     testArray[0] = tokenURIString1;
    //     // deploy wCreator Contract
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
    //         mintPricePerToken: mintPrice   
    //     });            
    //     vm.stopPrank();
    //     address createArtifactCaller = address(1);
    //     vm.deal(createArtifactCaller, 1 ether);
    //     vm.startPrank(createArtifactCaller);
    //     wildMachine.createArtifact{
    //         value: mintPrice * testArray.length
    //     }(configuredDrop, createArtifactCaller, testArray);
    //     assertEq(ERC721Drop(payable(configuredDrop)).saleDetails().totalMinted, 1);    
    //     assertEq(createArtifactCaller.balance, 1 ether - (mintPrice));
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString1); 
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString1);
    //     vm.stopPrank();
        
    //     // example of non zora drop admin, token owner, or jen stark
    //     //      being barred from updating tokenURI post mint
    //     vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
    //     vm.expectRevert();
    //     wildRenderer.updateArtifact(configuredDrop, 1, tokenURIString2);
    //     vm.stopPrank();

    //     // example of token owner being able to change tokenURI
    //     vm.startPrank(createArtifactCaller);
    //     wildRenderer.updateArtifact(configuredDrop, 1, tokenURIString2);
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString2);
    //     vm.stopPrank();

    //     // example of zora drop admin being able to change tokenURI
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     wildRenderer.updateArtifact(configuredDrop, 1, tokenURIString1);
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString1);
    //     vm.stopPrank();         

    //     // example of wildcardAddress being able to change tokenURI
    //     vm.startPrank(DEFAULT_WILDCARD_ADDRESS);
    //     wildRenderer.updateArtifact(configuredDrop, 1, tokenURIString3);
    //     assertEq(wildRenderer.artifactInfo(configuredDrop, 1), tokenURIString3);
    //     vm.stopPrank();        
    // }    

    // function test_updateContractURIPostDeploy() public { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     // deploy wCreator Contract
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
    //         mintPricePerToken: mintPrice   
    //     });            
    //     vm.stopPrank();
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString1); 
    //     vm.stopPrank();
        
    //     // example of non zora drop admin being barred from updating contractURI post deploy
    //     vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
    //     vm.expectRevert();
    //     wildRenderer.updateContractURI(configuredDrop, contractURIString2);
    //     vm.stopPrank();
        
    //     // example of zora drop admin being able to update contractURI post deploy        
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     wildRenderer.updateContractURI(configuredDrop, contractURIString2);
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString2);
    // }    

    // function test_updateWildcardAddressPostDeploy() public { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     // deploy wCreator Contract
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
    //         mintPricePerToken: mintPrice   
    //     });            
    //     assertEq(wildRenderer.wildcardInfo(configuredDrop), DEFAULT_WILDCARD_ADDRESS); 
    //     vm.stopPrank();
        
    //     // example of non zora drop admin being barred from updating wildcardAddress post deploy
    //     vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
    //     vm.expectRevert();
    //     wildRenderer.updateWildcardAddress(configuredDrop, SECONDARY_WILDCARD_ADDRESS);
    //     vm.stopPrank();
        
    //     // example of zora drop admin being able to update wildcardAddress post deploy        
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     wildRenderer.updateWildcardAddress(configuredDrop, SECONDARY_WILDCARD_ADDRESS);
    //     assertEq(wildRenderer.wildcardInfo(configuredDrop), SECONDARY_WILDCARD_ADDRESS);
    //     vm.stopPrank();

    //     // example of wildcardAddress being able to update wildcardAddress post deploy        
    //     vm.startPrank(SECONDARY_WILDCARD_ADDRESS);
    //     wildRenderer.updateWildcardAddress(configuredDrop, DEFAULT_OWNER_ADDRESS);
    //     assertEq(wildRenderer.wildcardInfo(configuredDrop), DEFAULT_OWNER_ADDRESS);
    //     vm.stopPrank();        
    // }     

    // function test_updateMintPricePerTokenPostDeploy() public { 
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     // deploy wCreator Contract
    //     WildCreator wCreator = new WildCreator(
    //         address(creator),
    //         wildRenderer,
    //         address(wildMachine)
    //     );
    //     //  deploy + configure ZORA drop with WildMachine architecture
    //     address configuredDrop = wCreator.createArtifactMachine({
    //         name: "Test NFT",
    //         symbol: "TNFT",
    //         defaultAdmin: DEFAULT_OWNER_ADDRESS,
    //         editionSize: 1000,
    //         royaltyBPS: 1000,
    //         fundsRecipient: payable(DEFAULT_OWNER_ADDRESS),
    //         saleConfig: IERC721Drop.SalesConfiguration({
    //             publicSaleStart: 0,
    //             publicSaleEnd: 0,
    //             presaleStart: 0,
    //             presaleEnd: 0,
    //             publicSalePrice: 0,
    //             maxSalePurchasePerAddress: 0,
    //             presaleMerkleRoot: bytes32(0)
    //         }),
    //         contractURI: contractURIString1,
    //         wildcardAddress: DEFAULT_WILDCARD_ADDRESS,
    //         mintPricePerToken: mintPrice   
    //     }); 
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString1); 
    //     vm.stopPrank();
        
    //     // example of non zora drop admin being barred from updating contractURI post deploy
    //     vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
    //     vm.expectRevert();
    //     wildRenderer.updateContractURI(configuredDrop, contractURIString2);
    //     vm.stopPrank();
        
    //     // example of zora drop admin being able to update contractURI post deploy        
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     wildRenderer.updateContractURI(configuredDrop, contractURIString2);
    //     assertEq(wildRenderer.contractURIInfo(configuredDrop), contractURIString2);
    // }    
}