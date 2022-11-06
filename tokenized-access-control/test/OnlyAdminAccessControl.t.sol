// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {OnlyAdminAccessControl} from "../src/OnlyAdminAccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {OnlyAdminMockCurator} from "./mocks/OnlyAdminMockCurator.sol";

contract OnlyAdminAccessControlTest is DSTest {

    // Init Variables
    Vm public constant vm = Vm(HEVM_ADDRESS);
    address payable public constant DEFAULT_OWNER_ADDRESS =
        payable(address(0x999));
    address payable public constant DEFAULT_NON_OWNER_ADDRESS =
        payable(address(0x888));        

    function setUp() public {
        // deploy NFT contract
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        vm.stopPrank();
    }

    function test_incorrectAdminSetup() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMockCurator mockCurator = new OnlyAdminMockCurator();
        vm.expectRevert("admin cannot be zero address");
        mockCurator.initializeAccessControl(
            address(adminAccessControl), 
            address(0)
        );    
    }       

    function test_AdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMockCurator mockCurator = new OnlyAdminMockCurator();
        mockCurator.initializeAccessControl(
            address(adminAccessControl), 
            address(DEFAULT_OWNER_ADDRESS)
        );
        assertTrue(mockCurator.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest()); 
    }        

    function test_ChangeAdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMockCurator mockCurator = new OnlyAdminMockCurator();
        mockCurator.initializeAccessControl(
            address(adminAccessControl), 
            address(DEFAULT_OWNER_ADDRESS)
        );
        assertTrue(mockCurator.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest()); 

        adminAccessControl.updateAdmin(address(mockCurator), DEFAULT_NON_OWNER_ADDRESS);
        assertTrue(adminAccessControl.getAdminInfo(address(mockCurator)) == DEFAULT_NON_OWNER_ADDRESS);
        
        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        
        assertTrue(mockCurator.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest()); 
    }          

    function test_NameTest() public {
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();
        assertEq(adminAccessControl.name(), "OnlyAdminAccessControl");
    }    
}