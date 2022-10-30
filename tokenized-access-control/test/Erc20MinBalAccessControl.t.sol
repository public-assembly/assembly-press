// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {Erc20MinBalAccessControl} from "../src/Erc20MinBalAccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {MockCurator} from "./MockCurator.sol";

contract Erc20MinBalAccessControlTest is DSTest {
    // Init Variables
    ERC20PresetMinterPauser erc20Curator;
    ERC20PresetMinterPauser erc20Manager;
    ERC20PresetMinterPauser erc20Admin;
    Vm public constant vm = Vm(HEVM_ADDRESS);
    address payable public constant DEFAULT_OWNER_ADDRESS =
        payable(address(0x999));
    address payable public constant DEFAULT_NON_OWNER_ADDRESS =
        payable(address(0x888));

    function setUp() public {
        // deploy NFT contract
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc20Curator = new ERC20PresetMinterPauser("20Curator", "20C");
        erc20Manager = new ERC20PresetMinterPauser("20Manager", "20M");
        erc20Admin = new ERC20PresetMinterPauser("20Admin", "20AD");
        vm.stopPrank();
    }

    function expectIsCurator(MockCurator mockCurator) internal {
        assertTrue(mockCurator.getAccessLevelForUser() == 1);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }

    function expectIsAdmin(MockCurator mockCurator) internal {
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest());
    }

    function test_revertUpdateAllAccessByCurator() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Curator.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        Erc20MinBalAccessControl e20AccessControl = new Erc20MinBalAccessControl();
        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        expectIsCurator(mockCurator);

        vm.expectRevert();
        e20AccessControl.updateAllAccess(
            address(mockCurator),
            erc20Curator,
            erc20Manager,
            erc20Admin,
            8.08 ether,
            8.08 ether,
            8.08 ether
        );
    }

    function test_updateAllAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Admin.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        Erc20MinBalAccessControl e20AccessControl = new Erc20MinBalAccessControl();
        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        expectIsAdmin(mockCurator);

        e20AccessControl.updateAllAccess(
            address(mockCurator),
            erc20Curator,
            erc20Manager,
            erc20Admin,
            8.08 ether,
            8.08 ether,
            8.08 ether
        );

        Erc20MinBalAccessControl.AccessLevelInfo
            memory newAccessLevel = e20AccessControl.getAccessInfo(
                address(mockCurator)
            );
        assertEq(address(newAccessLevel.curatorAccess), address(erc20Curator));
        assertEq(address(newAccessLevel.managerAccess), address(erc20Manager));
        assertEq(address(newAccessLevel.adminAccess), address(erc20Admin));
        assertEq(newAccessLevel.curatorMinimumBalance, 8.08 ether);
        assertEq(newAccessLevel.managerMinimumBalance, 8.08 ether);
        assertEq(newAccessLevel.adminMinimumBalance, 8.08 ether);
        assertTrue(!mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }

    // function test_CuratorAccess() public {
    //     vm.startPrank(DEFAULT_OWNER_ADDRESS);
    //     uint256 tokenBalance = 1 ether;
    //     erc20Curator.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
    //     Erc20MinBalAccessControl e20AccessControl = new Erc20MinBalAccessControl();

    //     MockCurator mockCurator = new MockCurator();
    //     mockCurator.initializeAccessControl(
    //         address(e20AccessControl),
    //         address(erc20Curator),
    //         address(erc20Manager),
    //         address(erc20Admin)
    //     );
    //     assertTrue(
    //         mockCurator.accessControlProxy() == address(e20AccessControl)
    //     );
    //     assertTrue(mockCurator.getAccessLevelForUser() == 1);
    //     assertTrue(mockCurator.curatorAccessTest());
    //     assertTrue(!mockCurator.managerAccessTest());
    //     assertTrue(!mockCurator.adminAccessTest());

    //     erc20Curator.transfer(DEFAULT_NON_OWNER_ADDRESS, tokenBalance);
    //     assertTrue(mockCurator.getAccessLevelForUser() == 0);
    //     assertTrue(!mockCurator.curatorAccessTest());
    //     assertTrue(!mockCurator.managerAccessTest());
    //     assertTrue(!mockCurator.adminAccessTest());

    //     vm.stopPrank();
    //     vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

    //     assertTrue(mockCurator.getAccessLevelForUser() == 1);
    //     assertTrue(mockCurator.curatorAccessTest());
    //     assertTrue(!mockCurator.managerAccessTest());
    //     assertTrue(!mockCurator.adminAccessTest());
    // }
}
