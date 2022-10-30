// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {ERC721PresetMinterPauserAutoId} from "openzeppelin-contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {Erc721AccessControl} from "../src/Erc721AccessControl.sol";
import {IAccessControlRegistry} from "../src/interfaces/IAccessControlRegistry.sol";
import {MockCurator} from "./MockCurator.sol";

contract Erc721AccessControlTest is DSTest {

    // Init Variables
    ERC721PresetMinterPauserAutoId erc721Curator;
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
        erc721Curator = new ERC721PresetMinterPauserAutoId("721Curator", "721C", "baseURI/");
        erc721Manager = new ERC721PresetMinterPauserAutoId("721Manager", "721M", "baseURI/");
        erc721Admin = new ERC721PresetMinterPauserAutoId("721Admin", "721AD", "baseURI/");
        vm.stopPrank();
    }

    function test_CuratorAccess() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721Curator.mint(DEFAULT_OWNER_ADDRESS);
        Erc721AccessControl e721AccessControl = new Erc721AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721Curator), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(mockCurator.accessControlProxy() == address(e721AccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 1);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(!mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        erc721Curator.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
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
        erc721Manager.mint(DEFAULT_OWNER_ADDRESS);
        Erc721AccessControl e721AccessControl = new Erc721AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721Curator), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(mockCurator.accessControlProxy() == address(e721AccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 2);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(!mockCurator.adminAccessTest());

        erc721Manager.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
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
        erc721Admin.mint(DEFAULT_OWNER_ADDRESS);
        Erc721AccessControl e721AccessControl = new Erc721AccessControl();

        MockCurator mockCurator = new MockCurator();
        mockCurator.initializeAccessControl(
            address(e721AccessControl), 
            address(erc721Curator), 
            address(erc721Manager), 
            address(erc721Admin)
        );
        assertTrue(mockCurator.accessControlProxy() == address(e721AccessControl));
        assertTrue(mockCurator.getAccessLevelForUser() == 3);
        assertTrue(mockCurator.curatorAccessTest());
        assertTrue(mockCurator.managerAccessTest());
        assertTrue(mockCurator.adminAccessTest());

        erc721Admin.transferFrom(
            DEFAULT_OWNER_ADDRESS, 
            DEFAULT_NON_OWNER_ADDRESS, 
            0
        );
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