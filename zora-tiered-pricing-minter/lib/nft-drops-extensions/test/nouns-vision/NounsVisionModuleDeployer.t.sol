// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";

import {NounsVisionExchangeDeployer} from "../../src/nouns-vision/NounsVisionExchangeDeployer.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {ZoraNFTCreatorV1} from "zora-drops-contracts/ZoraNFTCreatorV1.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {DropMetadataRenderer} from "zora-drops-contracts/metadata/DropMetadataRenderer.sol";
import {EditionMetadataRenderer} from "zora-drops-contracts/metadata/EditionMetadataRenderer.sol";
import {IZoraFeeManager} from "zora-drops-contracts/interfaces/IZoraFeeManager.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {SharedNFTLogic} from "zora-drops-contracts/utils/SharedNFTLogic.sol";
import {MockRenderer} from "../utils/MockRenderer.sol";

contract ERC721DropMinterModuleTest is DSTest {
    address constant OWNER_ADDRESS = address(0x123);
    Vm public constant vm = Vm(HEVM_ADDRESS);

    function test_SetupMinter() public {
        MockRenderer mockRenderer = new MockRenderer();
        ERC721Drop impl = new ERC721Drop(
            IZoraFeeManager(address(0x0)),
            address(0x0),
            FactoryUpgradeGate(address(0x0))
        );

        ZoraNFTCreatorV1 creator = new ZoraNFTCreatorV1(
            address(impl),
            EditionMetadataRenderer(address(0x10)),
            DropMetadataRenderer(address(0x10))
        );

        ERC721Drop source = ERC721Drop(
            payable(
                address(
                    new ERC721DropProxy(
                        address(impl),
                        abi.encodeWithSelector(
                            ERC721Drop.initialize.selector,
                            "Source NFT",
                            "SRC",
                            "TSTZ",
                            OWNER_ADDRESS,
                            address(0x0),
                            10,
                            10,
                            IERC721Drop.SalesConfiguration({
                                publicSaleStart: 0,
                                publicSaleEnd: 0,
                                presaleStart: 0,
                                presaleEnd: 0,
                                publicSalePrice: 0,
                                maxSalePurchasePerAddress: 0,
                                presaleMerkleRoot: 0x0
                            }),
                            mockRenderer,
                            ""
                        )
                    )
                )
            )
        );
        NounsVisionExchangeDeployer deployer = new NounsVisionExchangeDeployer(
            "DROP TARGET",
            "DRPTG",
            "TARG",
            100,
            1000,
            payable(0x9444390c01Dd5b7249E53FAc31290F7dFF53450D),
            address(creator),
            SharedNFTLogic(0x2a3245d54E5407E276c47f0C181a22bf90c797Ce),
            IERC721Drop(source)
        );
    }
}
