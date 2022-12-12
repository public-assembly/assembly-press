// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";

import {NounsVisionExchangeMinterModule} from "../../src/nouns-vision/NounsVisionExchangeMinterModule.sol";
import {DistributedGraphicsEdition} from "../../src/distributed-graphics-editions/DistributedGraphicsEdition.sol";

import {SharedNFTLogic} from "zora-drops-contracts/utils/SharedNFTLogic.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {IZoraFeeManager} from "zora-drops-contracts/interfaces/IZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";
import {IERC721AUpgradeable} from "erc721a-upgradeable/IERC721AUpgradeable.sol";
import {MockRenderer} from "../utils/MockRenderer.sol";

contract ERC721DropMinterModuleTest is DSTest {
    address constant OWNER_ADDRESS = address(0x123);
    address constant RECIPIENT_ADDRESS = address(0x333);
    ERC721Drop impl;
    ERC721Drop drop;
    DistributedGraphicsEdition renderer;
    SharedNFTLogic sharedLogic;
    Vm public constant vm = Vm(HEVM_ADDRESS);

    function setUp() public {
        impl = new ERC721Drop(
            IZoraFeeManager(address(0x0)),
            address(0x0),
            FactoryUpgradeGate(address(0x0))
        );
        sharedLogic = new SharedNFTLogic();
        renderer = new DistributedGraphicsEdition(sharedLogic);
    }

    modifier withDrop(uint256 limit, bytes memory init) {
        drop = ERC721Drop(
            payable(
                address(
                    new ERC721DropProxy(
                        address(impl),
                        abi.encodeWithSelector(
                            ERC721Drop.initialize.selector,
                            "Source NFT",
                            "SRC",
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
                            renderer,
                            init
                        )
                    )
                )
            )
        );
        _;
    }

    function testForDropThree()
        public
        withDrop(
            20,
            abi.encode(
                "Testing Description",
                "https://videos.example/",
                "https://images.example/",
                3,
                false
            )
        )
    {
        vm.startPrank(OWNER_ADDRESS);
        drop.adminMint(RECIPIENT_ADDRESS, 10);
        assertEq(
            drop.tokenURI(1),
            "data:application/json;base64,eyJuYW1lIjogIlNvdXJjZSBORlQgMS8xMCIsICJkZXNjcmlwdGlvbiI6ICJUZXN0aW5nIERlc2NyaXB0aW9uIiwgImltYWdlIjogImh0dHBzOi8vdmlkZW9zLmV4YW1wbGUvMT9pZD0xIiwgImFuaW1hdGlvbl91cmwiOiAiaHR0cHM6Ly9pbWFnZXMuZXhhbXBsZS8xP2lkPTEiLCAicHJvcGVydGllcyI6IHsibnVtYmVyIjogMSwgIm5hbWUiOiAiU291cmNlIE5GVCJ9fQ=="
        );
        assertEq(
            drop.tokenURI(2),
            "data:application/json;base64,eyJuYW1lIjogIlNvdXJjZSBORlQgMi8xMCIsICJkZXNjcmlwdGlvbiI6ICJUZXN0aW5nIERlc2NyaXB0aW9uIiwgImltYWdlIjogImh0dHBzOi8vdmlkZW9zLmV4YW1wbGUvMj9pZD0yIiwgImFuaW1hdGlvbl91cmwiOiAiaHR0cHM6Ly9pbWFnZXMuZXhhbXBsZS8yP2lkPTIiLCAicHJvcGVydGllcyI6IHsibnVtYmVyIjogMiwgIm5hbWUiOiAiU291cmNlIE5GVCJ9fQ=="
        );
        assertEq(
            drop.tokenURI(3),
            "data:application/json;base64,eyJuYW1lIjogIlNvdXJjZSBORlQgMy8xMCIsICJkZXNjcmlwdGlvbiI6ICJUZXN0aW5nIERlc2NyaXB0aW9uIiwgImltYWdlIjogImh0dHBzOi8vdmlkZW9zLmV4YW1wbGUvMz9pZD0zIiwgImFuaW1hdGlvbl91cmwiOiAiaHR0cHM6Ly9pbWFnZXMuZXhhbXBsZS8zP2lkPTMiLCAicHJvcGVydGllcyI6IHsibnVtYmVyIjogMywgIm5hbWUiOiAiU291cmNlIE5GVCJ9fQ=="
        );
        assertEq(
            drop.tokenURI(4),
            "data:application/json;base64,eyJuYW1lIjogIlNvdXJjZSBORlQgNC8xMCIsICJkZXNjcmlwdGlvbiI6ICJUZXN0aW5nIERlc2NyaXB0aW9uIiwgImltYWdlIjogImh0dHBzOi8vdmlkZW9zLmV4YW1wbGUvND9pZD00IiwgImFuaW1hdGlvbl91cmwiOiAiaHR0cHM6Ly9pbWFnZXMuZXhhbXBsZS80P2lkPTQiLCAicHJvcGVydGllcyI6IHsibnVtYmVyIjogNCwgIm5hbWUiOiAiU291cmNlIE5GVCJ9fQ=="
        );
    }

    function testForDropRandomThree()
        public
        withDrop(
            20,
            abi.encode(
                "Testing Description",
                "https://videos.example/",
                "https://images.example/",
                3,
                true
            )
        )
    {
        vm.startPrank(OWNER_ADDRESS);
        drop.adminMint(RECIPIENT_ADDRESS, 10);
        drop.tokenURI(1);
        drop.tokenURI(2);
        drop.tokenURI(3);
        drop.tokenURI(4);
        drop.tokenURI(5);
        assertEq(drop.tokenURI(4), "");
    }
}
