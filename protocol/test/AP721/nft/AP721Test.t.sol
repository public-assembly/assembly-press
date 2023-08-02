// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {AP721Config} from "../utils/setup/AP721Config.sol";

import {AP721} from "../../../src/core/token/AP721/nft/AP721.sol";
import {IERC5192} from "../../../src/core/token/AP721/nft/interfaces/IERC5192.sol";

import {MockLogic} from "../utils/mocks/logic/MockLogic.sol";
import {MockRenderer} from "../utils/mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721Test is AP721Config {
    function test_initialize() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );

        require(AP721(payable(newAP721)).owner() == AP721_ADMIN, "owner not set up correctly");
        require(
            keccak256(bytes(AP721(payable(newAP721)).name())) == keccak256(bytes(CONTRACT_NAME)),
            "name not set up correctly"
        );
        require(
            keccak256(bytes(AP721(payable(newAP721)).symbol())) == keccak256(bytes(CONTRACT_SYMBOL)),
            "symbol not set up correctly"
        );
        require(AP721(payable(newAP721)).getDatabase() == address(database), "database not set up correctly");
        require(
            AP721(payable(newAP721)).supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support"
        );
        require(AP721(payable(newAP721)).supportsInterface(type(IERC5192).interfaceId) == true, "doesn't support");
    }

    function test_db_access() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );

        vm.startPrank(address(database));

        AP721(payable(newAP721)).mint(AP721_ADMIN, 3);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 3, "mint not processed correctly");

        AP721(payable(newAP721)).burn(1);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 2, "burn not processed correctly");

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 2;
        tokenIds[1] = 3;
        AP721(payable(newAP721)).burnBatch(tokenIds);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 0, "burn batch not processed correctly");
    }

    function test_Revert_non_db_access() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );

        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        AP721(payable(newAP721)).initialize({initialOwner: address(0), database: address(0), init: BYTES_ZERO_VALUE});

        vm.expectRevert(abi.encodeWithSignature("Msg_Sender_Not_Database()"));
        AP721(payable(newAP721)).mint(address(1), 1);

        vm.expectRevert(abi.encodeWithSignature("Msg_Sender_Not_Database()"));
        AP721(payable(newAP721)).burn(1);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.expectRevert(abi.encodeWithSignature("Msg_Sender_Not_Database()"));
        AP721(payable(newAP721)).burnBatch(tokenIds);
    }

    function test_nonTransferableTokens() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );

        vm.prank(address(database));
        AP721(payable(newAP721)).mint(AP721_ADMIN, 1);
        vm.prank(AP721_ADMIN);
        vm.expectRevert(abi.encodeWithSignature("Non_Transferrable_Token()"));
        AP721(payable(newAP721)).safeTransferFrom(AP721_ADMIN, address(0x123), 1, new bytes(0));
    }

    function test_transferableTokens() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            TRANSFERABLE
        );

        vm.prank(address(database));
        AP721(payable(newAP721)).mint(AP721_ADMIN, 1);
        vm.prank(AP721_ADMIN);
        AP721(payable(newAP721)).safeTransferFrom(AP721_ADMIN, address(0x123), 1, new bytes(0));
        require(AP721(payable(newAP721)).balanceOf(address(0x123)) == 1, "transfer not processed correctly");
    }
}

/*
Execution Paths
    - mint, burn, burn batch should revert if not called by database - TESTED ✅
    - mint, burn, burn batch should pass if called by database - TESTED ✅
    - safeTransferFrom should revert if token transferability set to false in database - TESTED ✅
    - safeTransferFrom should pass if token transferability set to true in database - TESTED ✅

thoughts after first round of tests
    - should token ownership, contract ownership, and contract upgrades be restricted through DB as well?

Missing tests for
    - upgrades
    - contract ownership transfer
*/
