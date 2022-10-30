// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {Erc20AccessControl} from "../src/Erc20AccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {MockCurator} from "./MockCurator.sol";

contract Erc20AccessControlTest is DSTest {
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

    function test_CuratorAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        uint256 tokenBalance = 1 ether;
        erc20Curator.mint(DEFAULT_OWNER_ADDRESS, tokenBalance);
        Erc20AccessControl e20AccessControl = new Erc20AccessControl();

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
        Erc20AccessControl e20AccessControl = new Erc20AccessControl();

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
        Erc20AccessControl e20AccessControl = new Erc20AccessControl();

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
}
