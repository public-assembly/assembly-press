// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ERC721PresetMinterPauserAutoId} from "openzeppelin-contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {ERC721AccessControl} from "../src/ERC721AccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {ERC721AccessMock} from "./mocks/ERC721AccessMock.sol";

contract ERC721AccessControlTest is DSTest {

    // Init Variables
    ERC721PresetMinterPauserAutoId erc721User;
    ERC721PresetMinterPauserAutoId erc721Manager;
    ERC721PresetMinterPauserAutoId erc721Admin;
    Vm public constant vm = Vm(HEVM_ADDRESS);
    address payable public constant DEFAULT_OWNER_ADDRESS =
        payable(address(0x999));
    address payable public constant DEFAULT_NON_OWNER_ADDRESS =
        payable(address(0x888));        

    function setUp() public {
        // deploy NFT contract
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721User = new ERC721PresetMinterPauserAutoId("721User", "721U", "baseURI/");
        erc721Manager = new ERC721PresetMinterPauserAutoId("721Manager", "721M", "baseURI/");
        erc721Admin = new ERC721PresetMinterPauserAutoId("721Admin", "721AD", "baseURI/");
        vm.stopPrank();
    }

    function test_UserAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721User.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();

        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 1);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());

        erc721User.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );

        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

        assertTrue(erc721AccessMock.getAccessLevelForUser() == 1);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        
    }       

    function test_ManagerAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721Manager.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();

        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 2);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());

        erc721Manager.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 2);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        
    }           

    function test_AdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();

        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(erc721AccessMock.managerAccessTest());
        assertTrue(erc721AccessMock.adminAccessTest());

        erc721Admin.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);
        
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);
        assertTrue(erc721AccessMock.userAccessTest());
        assertTrue(erc721AccessMock.managerAccessTest());
        assertTrue(erc721AccessMock.adminAccessTest());        
    }       

    function test_noCuratorInitialized() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721User.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();

        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(0), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());

        erc721User.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        

        vm.stopPrank();
        vm.startPrank(DEFAULT_NON_OWNER_ADDRESS);

        assertTrue(erc721AccessMock.getAccessLevelForUser() == 0);
        assertTrue(!erc721AccessMock.userAccessTest());
        assertTrue(!erc721AccessMock.managerAccessTest());
        assertTrue(!erc721AccessMock.adminAccessTest());        
    }               

    function test_NameTest() public {
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        assertEq(e721AccessControl.name(), "ERC721AccessControl");
    }    
}