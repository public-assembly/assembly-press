// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {ERC20AccessControl} from "../src/ERC20AccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {MockCurator} from "./MockCurator.sol";

contract ERC20AccessControlTest is DSTest {
    // Init Variables
    ERC20PresetMinterPauser erc20Curator;
    ERC20PresetMinterPauser erc20Manager;
    ERC20PresetMinterPauser erc20Admin;
    Vm public constant vm = Vm(HEVM_ADDRESS);
    address payable public constant DEFAULT_OWNER_ADDRESS =
        payable(address(0x999));
    address payable public constant DEFAULT_NON_OWNER_ADDRESS =
        payable(address(0x888));
    address payable public constant DEFAULT_ADMIN_ADDRESS =
        payable(address(0x777));

    function setUp() public {
        // deploy NFT contract
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc20Curator = new ERC20PresetMinterPauser("20Curator", "20C");
        erc20Manager = new ERC20PresetMinterPauser("20Manager", "20M");
        erc20Admin = new ERC20PresetMinterPauser("20Admin", "20AD");
        vm.stopPrank();
    }

    function test_CuratorAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Curator.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        ERC20AccessControl e20AccessControl = new ERC20AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        assertTrue(
            mockCurator.accessControlProxy() == address(e20AccessControl)
        );
        assertTrue(mockCurator.getAccessLevelForUser() == 1);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        erc20Curator.transfer(DEFAULT_NON_OWNER_ADDRESS, tokenBalance);
        assertTrue(mockCurator.getAccessLevelForUser() == 0);
        assertTrue(!mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

        assertTrue(mockCurator.getAccessLevelForUser() == 1);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }

    function test_ManagerAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Manager.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        ERC20AccessControl e20AccessControl = new ERC20AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        assertTrue(
            mockCurator.accessControlProxy() == address(e20AccessControl)
        );
        assertTrue(mockCurator.getAccessLevelForUser() == 2);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        erc20Manager.transfer(DEFAULT_NON_OWNER_ADDRESS, tokenBalance);
        assertTrue(mockCurator.getAccessLevelForUser() == 0);
        assertTrue(!mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

        assertTrue(mockCurator.getAccessLevelForUser() == 2);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }

    function test_AdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Admin.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        ERC20AccessControl e20AccessControl = new ERC20AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        assertTrue(
            mockCurator.accessControlProxy() == address(e20AccessControl)
        );
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest());

        erc20Admin.transfer(DEFAULT_NON_OWNER_ADDRESS, tokenBalance);
        assertTrue(mockCurator.getAccessLevelForUser() == 0);
        assertTrue(!mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest());
    }

    function test_updateCuratorAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Admin.mint(DEFAULT_ADMIN_ADDRESS, tokenBalance);
        erc20Curator.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        ERC20AccessControl e20AccessControl = new ERC20AccessControl();
        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e20AccessControl),
            address(erc20Curator),
            address(erc20Manager),
            address(erc20Admin)
        );
        ERC20AccessControl.AccessLevelInfo
            memory newAccessLevel = e20AccessControl.getAccessInfo(
                address(mockCurator)
            );
        assertEq(address(newAccessLevel.curatorAccess), address(erc20Curator));
        expectIsCurator(mockCurator);

        ERC20PresetMinterPauser newERC20Curator = new ERC20PresetMinterPauser(
            "20Curator",
            "20C"
        );
        vm.stopPrank();
        vm.prank(DEFAULT_ADMIN_ADDRESS);
        e20AccessControl.updateCuratorAccess(
            address(mockCurator),
            newERC20Curator
        );
        vm.startPrank(DEFAULT_OWNER_ADDRESS);

        newAccessLevel = e20AccessControl.getAccessInfo(address(mockCurator));
        assertEq(
            address(newAccessLevel.curatorAccess),
            address(newERC20Curator)
        );
        expectNoAccess(mockCurator);
    }

    //////////////////////////////////////////////////
    // INTERNAL HELPERS
    //////////////////////////////////////////////////
    function expectIsCurator(MockCurator mockCurator) internal {
        assertTrue(mockCurator.getAccessLevelForUser() == 1);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }

    function expectNoAccess(MockCurator mockCurator) internal {
        assertTrue(mockCurator.getAccessLevelForUser() == 0);
        assertTrue(!mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());
    }
}
