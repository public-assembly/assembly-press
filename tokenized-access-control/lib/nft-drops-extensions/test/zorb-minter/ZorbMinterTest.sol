// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Vm} from "forge-std/Vm.sol";
import {DSTest} from "ds-test/test.sol";

import {SharedNFTLogic} from "zora-drops-contracts/utils/SharedNFTLogic.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {ERC721DropProxy} from "zora-drops-contracts/ERC721DropProxy.sol";
import {IZoraFeeManager} from "zora-drops-contracts/interfaces/IZoraFeeManager.sol";
import {FactoryUpgradeGate} from "zora-drops-contracts/FactoryUpgradeGate.sol";

import {ZorbMinter} from "../../src/zorb-minter/ZorbMinter.sol";
import {MockRenderer} from "../utils/MockRenderer.sol";

contract ZorbMinterTest is DSTest {
    address constant OWNER_ADDRESS = address(0x123);
    ERC721Drop impl;
    Vm public constant vm = Vm(HEVM_ADDRESS);

    function setUp() public {
        impl = new ERC721Drop(
            IZoraFeeManager(address(0x0)),
            address(0x0),
            FactoryUpgradeGate(address(0x0))
        );
    }

    function test_MintWithZorb() public {
        MockRenderer mockRenderer = new MockRenderer();
        ERC721Drop drop = ERC721Drop(
            payable(
                address(
                    new ERC721DropProxy(
                        address(impl),
                        abi.encodeWithSelector(
                            ERC721Drop.initialize.selector,
                            "zorb club",
                            "ZORBCLUB",
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

        ERC721Drop zorb = ERC721Drop(
            payable(
                address(
                    new ERC721DropProxy(
                        address(impl),
                        abi.encodeWithSelector(
                            ERC721Drop.initialize.selector,
                            "zorb source",
                            "ZORB",
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

        address ZORB_WHALE = address(0xcafebabe);
        vm.prank(OWNER_ADDRESS);
        zorb.adminMint(ZORB_WHALE, 10);

        ZorbMinter zorbMinter = new ZorbMinter(address(zorb));
        // Become the owner of the created drop
        vm.startPrank(OWNER_ADDRESS);
        // Grant minter role to the ZORB Minter for this drop
        drop.grantRole(drop.MINTER_ROLE(), address(zorbMinter));
        vm.stopPrank();

        // Attempt to mint without owning a zorb
        address RANDOM_USER = address(0xbbee1);
        uint256[] memory zorbIds = new uint256[](2);
        zorbIds[0] = 1;
        zorbIds[1] = 2;
        vm.expectRevert(
            abi.encodeWithSelector(
                ZorbMinter.DoesNotOwnZorb.selector,
                RANDOM_USER,
                1
            )
        );

        // Attepmt to mint Zorbs from random user that doesn't have them.
        vm.prank(RANDOM_USER);
        zorbMinter.mintWithZorbs(address(drop), zorbIds);

        // Transfer RANDOM_USER zorbs from the ZORB_WHALE
        vm.startPrank(ZORB_WHALE);
        zorb.transferFrom(ZORB_WHALE, RANDOM_USER, 1);
        zorb.transferFrom(ZORB_WHALE, RANDOM_USER, 2);
        vm.stopPrank();

        // Mint from RANDOM_USER
        vm.prank(RANDOM_USER);
        zorbMinter.mintWithZorbs(address(drop), zorbIds);

        // Check 2 NFTs were minted to RANDOM_USER
        assertEq(drop.balanceOf(RANDOM_USER), 2);
    }
}
