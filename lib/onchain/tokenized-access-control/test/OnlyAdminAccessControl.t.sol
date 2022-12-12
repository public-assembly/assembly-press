// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {OnlyAdminAccessControl} from "../src/OnlyAdminAccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {OnlyAdminMock} from "./mocks/OnlyAdminMock.sol";

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

        OnlyAdminMock mockOnlyAdmin = new OnlyAdminMock();
        vm.expectRevert("admin cannot be zero address");
        mockOnlyAdmin.initializeAccessControl(
            address(adminAccessControl), 
            address(0)
        );    
    }       

    function test_AdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMock mockOnlyAdmin = new OnlyAdminMock();
        mockOnlyAdmin.initializeAccessControl(
            address(adminAccessControl), 
            address(DEFAULT_OWNER_ADDRESS)
        );
        assertTrue(mockOnlyAdmin.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockOnlyAdmin.getAccessLevelForUser() == 3);
        assertTrue(mockOnlyAdmin.userAccessTest());
        assertTrue(mockOnlyAdmin.managerAccessTest());
        assertTrue(mockOnlyAdmin.adminAccessTest()); 
    }        

    function test_ChangeAdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMock mockOnlyAdmin = new OnlyAdminMock();
        mockOnlyAdmin.initializeAccessControl(
            address(adminAccessControl), 
            address(DEFAULT_OWNER_ADDRESS)
        );
        assertTrue(mockOnlyAdmin.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockOnlyAdmin.getAccessLevelForUser() == 3);
        assertTrue(mockOnlyAdmin.userAccessTest());
        assertTrue(mockOnlyAdmin.managerAccessTest());
        assertTrue(mockOnlyAdmin.adminAccessTest()); 

        adminAccessControl.updateAdmin(address(mockOnlyAdmin), DEFAULT_NON_OWNER_ADDRESS);
        assertTrue(adminAccessControl.getAdminInfo(address(mockOnlyAdmin)) == DEFAULT_NON_OWNER_ADDRESS);
        
        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        
        assertTrue(mockOnlyAdmin.accessControlProxy() == address(adminAccessControl));
        assertTrue(mockOnlyAdmin.getAccessLevelForUser() == 3);
        assertTrue(mockOnlyAdmin.userAccessTest());
        assertTrue(mockOnlyAdmin.managerAccessTest());
        assertTrue(mockOnlyAdmin.adminAccessTest()); 
    }          

    function test_NameTest() public {
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();
        assertEq(adminAccessControl.name(), "OnlyAdminAccessControl");
    }    

    function test_GetAdminInfo() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        OnlyAdminAccessControl adminAccessControl = new OnlyAdminAccessControl();

        OnlyAdminMock mockOnlyAdmin = new OnlyAdminMock();
        mockOnlyAdmin.initializeAccessControl(
            address(adminAccessControl), 
            address(DEFAULT_OWNER_ADDRESS)
        );
        assertTrue(mockOnlyAdmin.accessControlProxy() == address(adminAccessControl));        
        assertEq(adminAccessControl.getAdminInfo(address(mockOnlyAdmin)),  address(DEFAULT_OWNER_ADDRESS));
    }        
}