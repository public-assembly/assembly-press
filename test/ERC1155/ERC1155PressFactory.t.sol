// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC1155Press} from "../../src/token/ERC1155/ERC1155Press.sol";
import {ERC1155PressFactory} from "../../src/token/ERC1155/ERC1155PressFactory.sol";
import {ERC1155PressFactoryProxy} from "../../src/token/ERC1155/core/proxy/ERC1155PressFactoryProxy.sol";

contract ERC1155PressFactoryTest is Test {

    ERC1155PressFactory factoryProxy;
    address erc1155PressFactory;
    address erc1155PressFactory_secondImpl;
    address erc1155PressImpl;
    address mockFactoryImpl = address(0xFFF);
    address owner = address(0x123);
    address secondaryOwner = address(0x456);
    address nonOwner = address(0x789);    

    function setUp() public {
        erc1155PressImpl = address(new ERC1155Press());
        erc1155PressFactory = address(new ERC1155PressFactory(erc1155PressImpl));
        erc1155PressFactory_secondImpl = address(new ERC1155PressFactory(erc1155PressImpl));
        factoryProxy = ERC1155PressFactory(address(new ERC1155PressFactoryProxy(erc1155PressFactory, owner, secondaryOwner)));
        // should revert because proxy has just been initialized
        vm.expectRevert("Initializable: contract is already initialized");
        factoryProxy.initialize(owner, secondaryOwner);
        require(factoryProxy.owner() == owner, "owner not initialized correctly");
        require(factoryProxy.secondaryOwner() == secondaryOwner, "secondary owner not initialized correctly");     
    }    

    function test_safeTransferOwner() public {
        vm.startPrank(secondaryOwner);
        // should revert because nonOwner is not owner initialized on factory proxy
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        factoryProxy.safeTransferOwnership(secondaryOwner);
        vm.stopPrank();
        vm.startPrank(owner);
        factoryProxy.safeTransferOwnership(secondaryOwner);
        require(factoryProxy.pendingOwner() == secondaryOwner, "pending owner not set correctly");
        vm.stopPrank();
        vm.startPrank(nonOwner);
        // should revert because non pending owner is calling accept Ownership
        vm.expectRevert(abi.encodeWithSignature("ONLY_PENDING_OWNER()"));
        factoryProxy.acceptOwnership();
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        factoryProxy.acceptOwnership();
        require(factoryProxy.owner() == secondaryOwner, "ownership not transferred correctly");
        require(factoryProxy.pendingOwner() == address(0), "pending owner not cancelled correctly");
    }        

    function test_upgradeTo() public {
        vm.startPrank(nonOwner);
        // should revert because nonOwner is not either owner initialized on factory proxy
        vm.expectRevert(abi.encodeWithSignature("NOT_EITHER_OWNER()"));
        factoryProxy.upgradeTo(erc1155PressFactory_secondImpl);        
        vm.stopPrank();
        vm.startPrank(owner);
        // shouldnt revert because owner is calling upgrade
        factoryProxy.upgradeTo(erc1155PressFactory_secondImpl);

        // TODO: add test to confirm new implementation went through ??
    }

    function test_upgradeTo_AfterRevoke() public {
        vm.startPrank(secondaryOwner);
        factoryProxy.upgradeTo(erc1155PressFactory_secondImpl);
        // TODO: add test to confirm new implementation went through ??

        vm.stopPrank();
        vm.startPrank(owner);
        factoryProxy.resignSecondaryOwnership();
        require(factoryProxy.secondaryOwner() == address(0), "resign not correct");
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        // should revert now because secondaryOwner has had ownership removed
        vm.expectRevert(abi.encodeWithSignature("NOT_EITHER_OWNER()"));
        factoryProxy.upgradeTo(erc1155PressFactory);        
    }        
}