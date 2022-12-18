// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DropConfig} from "./DropConfig.sol";

import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";

import {Publisher} from "../src/Publisher.sol";
import {IPublisher} from "../src/interfaces/IPublisher.sol";

import {AssemblyPress} from "../src/AssemblyPress.sol";
import {IAssemblyPress} from "../src/interfaces/IAssemblyPress.sol";
import {AssemblyPressProxy} from "../src/AssemblyPressProxy.sol";

import {IOwnableUpgradeable} from "../src/utils/IOwnableUpgradeable.sol";
import {console} from "forge-std/console.sol";

contract AssemblyPressArchitectureTest is DropConfig {
    uint256 public mintPrice = 0;
    string public contractURIString1 = "test_contractURI_1/";
    string public contractURIString2 = "test_contractURI_2/";
    string public tokenURIString1 = "test_tokenURI_1/";
    bytes public tokenURIString1_encoded = abi.encode(tokenURIString1);
    string public tokenURIString2 = "test_tokenURI_2/";
    bytes public tokenURIString2_encoded = abi.encode(tokenURIString2);

    // Tests that the Assembly Press proxy initializes
    function test_initializeProxy() public {
        // Create a proxy of the Assembly Press instance
        AssemblyPressProxy assemblyPressProxy = new AssemblyPressProxy(
            address(assemblyPress),
            DEFAULT_OWNER_ADDRESS
        );
        // Assert that the owner of the proxy is the supplied owner
        assertEq(IOwnableUpgradeable(address(assemblyPressProxy)).owner(), DEFAULT_OWNER_ADDRESS);
    }

    // Tests that the Assembly Press initialization addresses are not the zero address
    function test_unallowedZeroAddressInitialization() public {
        vm.expectRevert(IAssemblyPress.CantSet_ZeroAddress.selector);
        // Create an instance of Assembly Press with the first argument being the zero address
        AssemblyPress assemblyPressOne = new AssemblyPress(
            address(0),
            publisher
        );
    }

    function test_implementationAddresses() public {
        Publisher publisherLocal = new Publisher();
        AssemblyPress assemblyPressLocal = new AssemblyPress(
            address(creator),
            publisherLocal
        );
        AssemblyPressProxy assemblyPressProxy = new AssemblyPressProxy(
            address(assemblyPressLocal),
            DEFAULT_OWNER_ADDRESS
        );

        Publisher publisherLocalAddress = AssemblyPress(address(assemblyPressProxy)).publisherImplementation();
        assertEq(address(publisherLocal), address(publisherLocalAddress));
        vm.expectRevert();
        assertEq(address(creator), address(0));
        assertEq(IOwnableUpgradeable(address(assemblyPressProxy)).owner(), DEFAULT_OWNER_ADDRESS);
    }

    function test_FactoryInitializeProxy() public {
        Publisher mockImplAddress = new Publisher();
        address defaultOwnerAddress = address(0x222);
        AssemblyPress assemblyPressOne = new AssemblyPress(
            address(creator),
            mockImplAddress
        );

        AssemblyPressProxy assemblyPressProxy = new AssemblyPressProxy(
            address(assemblyPressOne),
            DEFAULT_OWNER_ADDRESS
        );

        assertEq(IOwnableUpgradeable(address(assemblyPressProxy)).owner(), DEFAULT_OWNER_ADDRESS);
    }

    // DOES NOT PASS
    function test_createPublicationFromProxy() public {
        Publisher publisherLocal = new Publisher();
        AssemblyPress assemblyPressLocal = new AssemblyPress(
            address(creator),
            publisherLocal
        );
        // Create a proxy of the Assembly Press instance
        AssemblyPressProxy assemblyPressProxy = new AssemblyPressProxy(
            address(assemblyPressLocal),
            DEFAULT_OWNER_ADDRESS
        );
        // Call createPublication on the Assembly Press Proxy
        address zoraDrop = IAssemblyPress(address(assemblyPressProxy)).createPublication({
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
            mintPricePerToken: mintPrice,
            accessControl: address(onlyAdminAC),
            accessControlInit: accessControlInit
        });
        // ERC721Drop pubChannel = ERC721Drop(payable(zoraDrop));
        // assertEq(onlyAdminAC.getAccessLevel(address(publisher), DEFAULT_OWNER_ADDRESS), 3);
        // assertEq(pubChannel.contractURI(), contractURIString1);
    }

    function test_createPublication() public {
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
            mintPricePerToken: mintPrice,
            accessControl: address(onlyAdminAC),
            accessControlInit: accessControlInit
        });
        ERC721Drop pubChannel = ERC721Drop(payable(zoraDrop));
        (string memory s, address a, uint256 u) = publisher.pressInfo(zoraDrop);
        assertEq(s, contractURIString1);
        assertEq(a, address(onlyAdminAC));
        assertEq(u, mintPrice);
        assertEq(pubChannel.contractURI(), contractURIString1);
        assertEq(onlyAdminAC.getAccessLevel(address(publisher), DEFAULT_OWNER_ADDRESS), 3);
    }

    function test_publish() public {
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
        publisher.publish(zoraDrop, DEFAULT_OWNER_ADDRESS, artifacts);
        assertEq(pubChannel.saleDetails().totalMinted, 1);
        assertEq(pubChannel.tokenURI(1), tokenURIString1);

        // FIGURE OUT HOW TO TEST THE INDIVIDUAL VALUES FROM publisher.artifactInfo()
        // want to check if the address artifactRenderer + bytes memory artifactMetadata are correct
        // console.logBytes(tokenURIString1_encoded);
    }

    function test_edit() public {
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
        publisher.publish(zoraDrop, DEFAULT_OWNER_ADDRESS, artifacts_1);
        assertEq(pubChannel.saleDetails().totalMinted, 1);
        assertEq(pubChannel.tokenURI(1), tokenURIString1);

        IPublisher.ArtifactDetails[] memory artifacts_2 = new IPublisher.ArtifactDetails[](1);
        artifacts_2[0].artifactRenderer = address(defaultMetaDecoder);
        artifacts_2[0].artifactMetadata = tokenURIString2_encoded;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        publisher.edit(zoraDrop, tokenIds, artifacts_2);
        assertEq(pubChannel.tokenURI(1), tokenURIString2);
    }

    function test_editFailNoAccessControl() public {
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
        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        vm.expectRevert();
        publisher.updateContractURI(zoraDrop, contractURIString2);
        vm.expectRevert();
        publisher.updateMintPrice(zoraDrop, 100);
        vm.expectRevert();
        publisher.updateAccessControlWithData(zoraDrop, address(onlyAdminAC), accessControlInit2);
    }

    function test_editContractURI() public {
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
        publisher.updateContractURI(zoraDrop, contractURIString2);
        (string memory s, address a, uint256 u) = publisher.pressInfo(zoraDrop);
        assertEq(s, contractURIString2);
        assertEq(pubChannel.contractURI(), contractURIString2);
    }

    function test_editAccessControl() public {
        // startPrank inputs set msg.sender, tx.origin respectively
        vm.startPrank(DEFAULT_OWNER_ADDRESS, DEFAULT_OWNER_ADDRESS);
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
        publisher.updateAccessControlWithData(zoraDrop, address(onlyAdminAC), accessControlInit2);
        (string memory s, address a, uint256 u) = publisher.pressInfo(zoraDrop);
        assertEq(a, address(onlyAdminAC));
        assertEq(onlyAdminAC.getAccessLevel(address(publisher), DEFAULT_OWNER_ADDRESS), 0);
        assertEq(onlyAdminAC.getAccessLevel(address(publisher), DEFAULT_NON_OWNER_ADDRESS), 3);
    }

    function test_editMintPricePerToken() public {
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
        publisher.updateMintPrice(zoraDrop, 100);
        (string memory s, address a, uint256 u) = publisher.pressInfo(zoraDrop);
        assertEq(u, 100);
    }
}
