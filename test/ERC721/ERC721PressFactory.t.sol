// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IERC721PressFactory} from "../../src/token/ERC721/core/interfaces/IERC721PressFactory.sol";
import {IERC721Press} from "../../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {ERC721PressFactoryProxy} from "../../src/token/ERC721/core/proxy/ERC721PressFactoryProxy.sol";
import {ERC721PressFactory} from "../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721Press} from "../../src/token/ERC721/ERC721Press.sol";
import {ERC1967Proxy} from "openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ERC721PressFactoryTest is Test {

    ERC721PressFactory factoryProxy;
    address erc721PressFactory;
    address erc721PressFactory_secondImpl;
    address erc721PressImpl;
    address mockFactoryImpl = address(0xFFF);
    address owner = address(0x123);
    address secondaryOwner = address(0x456);
    address nonOwner = address(0x789);

    function setUp() public {
        erc721PressImpl = address(new ERC721Press());
        erc721PressFactory = address(new ERC721PressFactory(erc721PressImpl));
        erc721PressFactory_secondImpl = address(new ERC721PressFactory(erc721PressImpl));
        factoryProxy = ERC721PressFactory(address(new ERC721PressFactoryProxy(erc721PressFactory, owner, secondaryOwner)));
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
        factoryProxy.upgradeTo(erc721PressFactory_secondImpl);        
        vm.stopPrank();
        vm.startPrank(owner);
        // shouldnt revert because owner is calling upgrade
        factoryProxy.upgradeTo(erc721PressFactory_secondImpl);

        // TODO: add test to confirm new implementation went through ??
    }

    function test_upgradeTo_AfterRevoke() public {
        vm.startPrank(secondaryOwner);
        factoryProxy.upgradeTo(erc721PressFactory_secondImpl);
        // TODO: add test to confirm new implementation went through ??

        vm.stopPrank();
        vm.startPrank(owner);
        factoryProxy.resignSecondaryOwnership();
        require(factoryProxy.secondaryOwner() == address(0), "resign not correct");
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        // should revert now because secondaryOwner has had ownership removed
        vm.expectRevert(abi.encodeWithSignature("NOT_EITHER_OWNER()"));
        factoryProxy.upgradeTo(erc721PressFactory);        
    }    
}