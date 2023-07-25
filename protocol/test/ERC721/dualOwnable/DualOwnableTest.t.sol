// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {DualOwnable} from "../../../src/core/utils/ownable/dual/DualOwnable.sol";
import {IDualOwnable} from "../../../src/core/utils/ownable/dual/IDualOwnable.sol";

contract MockOwnedContract is DualOwnable {
    constructor(address initialOwner, address secondaryOwner) DualOwnable(initialOwner, secondaryOwner) {}

    function permissionedDoThing() public eitherOwner returns (bool) {
        return true;
    }
}

contract DualOwnableTest is Test {
    address public primaryOwner = address(0x111);
    address public secondaryOwner = address(0x222);
    address public nonOwner = address(0x333);
    MockOwnedContract public mockOwnedContract;

    function setUp() public {
        mockOwnedContract = new MockOwnedContract(primaryOwner, secondaryOwner);
    }

    function test_OwnershipSetup() public {
        mockOwnedContract.owner();
        assertEq(mockOwnedContract.owner(), primaryOwner);
        assertEq(mockOwnedContract.secondaryOwner(), secondaryOwner);
    }

    function test_GatedOnlyAdmin() public {
        vm.startPrank(primaryOwner);
        assertTrue(mockOwnedContract.permissionedDoThing());
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        assertTrue(mockOwnedContract.permissionedDoThing());
        vm.stopPrank();
        vm.startPrank(nonOwner);
        // should revert because being called by non primary/secondaryOwner
        vm.expectRevert(abi.encodeWithSignature("NOT_EITHER_OWNER()"));
        mockOwnedContract.permissionedDoThing();
    }

    function test_SafeTransferOwnership() public {
        address newOwner = address(0x99);
        assertEq(primaryOwner, mockOwnedContract.owner());
        vm.startPrank(nonOwner);
        // should revert because non owner calling transfer ownership
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        mockOwnedContract.safeTransferOwnership(newOwner);
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        // should revert because sceonary owner calling transfer primary ownership
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        mockOwnedContract.safeTransferOwnership(newOwner);
        vm.stopPrank();
        vm.prank(primaryOwner);
        mockOwnedContract.safeTransferOwnership(newOwner);
        assertEq(mockOwnedContract.pendingOwner(), newOwner);
        vm.startPrank(address(0x9));
        vm.expectRevert(abi.encodeWithSignature("ONLY_PENDING_OWNER()"));
        mockOwnedContract.acceptOwnership();
        vm.stopPrank();
        vm.startPrank(newOwner);
        mockOwnedContract.acceptOwnership();
        assertEq(mockOwnedContract.owner(), newOwner);
    }

    function test_CancelsOwnershipTransfer() public {
        address newOwner = address(0x99);
        vm.prank(primaryOwner);
        mockOwnedContract.safeTransferOwnership(newOwner);
        assertEq(mockOwnedContract.pendingOwner(), newOwner);
        assertEq(mockOwnedContract.owner(), primaryOwner);
        vm.prank(primaryOwner);
        mockOwnedContract.cancelOwnershipTransfer();
        assertEq(mockOwnedContract.pendingOwner(), address(0x0));
        assertEq(mockOwnedContract.owner(), primaryOwner);
    }

    function test_ResignOwnership() public {
        vm.prank(primaryOwner);
        mockOwnedContract.resignOwnership();
        assertEq(mockOwnedContract.owner(), address(0));
    }

    function test_TransferOwnershipSimple() public {
        address newOwner = address(0x99);
        assertEq(mockOwnedContract.pendingOwner(), address(0x0));
        assertEq(mockOwnedContract.owner(), primaryOwner);
        vm.prank(primaryOwner);
        mockOwnedContract.transferOwnership(newOwner);
        assertEq(mockOwnedContract.pendingOwner(), address(0x0));
        assertEq(mockOwnedContract.owner(), newOwner);
    }

    function test_NotTransferOwnershipZero() public {
        address newOwner = address(0x99);
        assertEq(mockOwnedContract.pendingOwner(), address(0x0));
        assertEq(mockOwnedContract.owner(), primaryOwner);
        vm.prank(primaryOwner);
        vm.expectRevert(abi.encodeWithSignature("OWNER_CANNOT_BE_ZERO_ADDRESS()"));
        mockOwnedContract.transferOwnership(address(0));
    }

    function test_PendingThenTransfer() public {
        address newOwner = address(0x99);
        vm.prank(primaryOwner);
        mockOwnedContract.safeTransferOwnership(address(0x123));
        assertEq(mockOwnedContract.pendingOwner(), address(0x123));
        assertEq(mockOwnedContract.owner(), primaryOwner);
        vm.prank(primaryOwner);
        mockOwnedContract.transferOwnership(newOwner);
        assertEq(mockOwnedContract.pendingOwner(), address(0x0));
        assertEq(mockOwnedContract.owner(), newOwner);
    }

    function test_TransferSecondaryOwnershipSimple() public {
        address newSecondaryOwner = address(0x99);
        assertEq(mockOwnedContract.secondaryOwner(), secondaryOwner);
        vm.prank(primaryOwner);
        mockOwnedContract.transferSecondaryOwnership(newSecondaryOwner);
        assertEq(mockOwnedContract.secondaryOwner(), newSecondaryOwner);
    }

    function test_ResignSecondaryOwnership_PrimaryOwner() public {
        vm.prank(primaryOwner);
        mockOwnedContract.resignSecondaryOwnership();
        assertEq(mockOwnedContract.secondaryOwner(), address(0));
    }

    function test_ResignSecondaryOwnership_SecondaryOwner() public {
        vm.prank(secondaryOwner);
        mockOwnedContract.resignSecondaryOwnership();
        assertEq(mockOwnedContract.secondaryOwner(), address(0));
    }
}
