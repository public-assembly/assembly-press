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
    ERC721PresetMinterPauserAutoId erc721Wildcard;
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
        erc721Wildcard = new ERC721PresetMinterPauserAutoId("721Wildcard", "721W", "baseURI/");
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

    function test_AdminAccessForACUpdates() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        erc721User.mint(DEFAULT_OWNER_ADDRESS);
        erc721Manager.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 2);

        vm.expectRevert();
        e721AccessControl.updateUserAccess(address(erc721AccessMock), address(erc721Wildcard));
        vm.expectRevert();
        e721AccessControl.updateManagerAccess(address(erc721AccessMock), address(erc721Wildcard));
        vm.expectRevert();
        e721AccessControl.updateAdminAccess(address(erc721AccessMock), address(erc721Wildcard));
        vm.expectRevert();
        e721AccessControl.updateAllAccess(address(erc721AccessMock), address(erc721Wildcard), address(erc721Wildcard), address(erc721Wildcard));                        

        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);

        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721User));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Manager));
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Admin));
        e721AccessControl.updateUserAccess(address(erc721AccessMock), address(erc721Wildcard));
        e721AccessControl.updateManagerAccess(address(erc721AccessMock), address(erc721Wildcard));
        e721AccessControl.updateAdminAccess(address(erc721AccessMock), address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Wildcard));

        vm.expectRevert();
        e721AccessControl.updateUserAccess(address(erc721AccessMock), address(erc721Admin));
        vm.expectRevert();
        e721AccessControl.updateManagerAccess(address(erc721AccessMock), address(erc721Admin));
        vm.expectRevert();
        e721AccessControl.updateAdminAccess(address(erc721AccessMock), address(erc721Admin));        
    }


    function test_UpdateUserAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);

        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721User));
        e721AccessControl.updateUserAccess(address(erc721AccessMock), address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721Wildcard));            
    }

    function test_UpdateManagerAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);

        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Manager));
        e721AccessControl.updateManagerAccess(address(erc721AccessMock), address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Wildcard));             
    }    

    function test_UpdateAdminAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);

        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Admin));
        e721AccessControl.updateAdminAccess(address(erc721AccessMock), address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Wildcard));         
    }      

    function test_UpdateAllAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(erc721AccessMock.accessControlProxy() == address(e721AccessControl));
        assertTrue(erc721AccessMock.getAccessLevelForUser() == 3);
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Admin));

        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721User));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Manager));
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Admin));      
        e721AccessControl.updateAllAccess(address(erc721AccessMock), address(erc721Wildcard), address(erc721Wildcard), address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721Wildcard));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Wildcard));        
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Wildcard));         
    }     

    function test_GetACInfo() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        ERC721AccessControl e721AccessControl = new ERC721AccessControl();
        ERC721AccessMock erc721AccessMock = new ERC721AccessMock();
        erc721AccessMock.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721User), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(address(e721AccessControl.getUserInfo(address(erc721AccessMock))) == address(erc721User));
        assertTrue(address(e721AccessControl.getManagerInfo(address(erc721AccessMock))) == address(erc721Manager));
        assertTrue(address(e721AccessControl.getAdminInfo(address(erc721AccessMock))) == address(erc721Admin)); 
        assertTrue(address(e721AccessControl.getAccessInfo(address(erc721AccessMock)).userAccess) == address(erc721User));
        assertTrue(address(e721AccessControl.getAccessInfo(address(erc721AccessMock)).managerAccess) == address(erc721Manager));
        assertTrue(address(e721AccessControl.getAccessInfo(address(erc721AccessMock)).adminAccess) == address(erc721Admin));
    }   
}
