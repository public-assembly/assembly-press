// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {AP721Config} from "../../utils/setup/AP721Config.sol";

import {AP721} from "../../../../src/core/token/AP721/nft/AP721.sol";

import {MockLogic} from "../../utils/mocks/logic/MockLogic.sol";
import {MockRenderer} from "../../utils/mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721DatabaseV1_StoreTest is AP721Config {
    
    function test_store() public {
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

        // setup data to store
        bytes memory tokenData = abi.encode("Assembly Press");
        bytes[] memory tokenDataArray = new bytes[](1);
        tokenDataArray[0] = tokenData;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        vm.prank(AP721_ADMIN);
        database.store(newAP721, encodedTokenDataArray);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(keccak256(database.readData(newAP721, 1)) == keccak256(tokenData), "data not stored + read correctly");
    }

    function test_read() public {
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

        // setup data to store
        bytes memory tokenData = abi.encode("Assembly Press");
        bytes[] memory tokenDataArray = new bytes[](1);
        tokenDataArray[0] = tokenData;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        vm.prank(AP721_ADMIN);
        database.store(newAP721, encodedTokenDataArray);
        require(keccak256(database.readData(newAP721, 1)) == keccak256(tokenData), "data not stored + read correctly");
    }

    function test_quantityTwo_store() public {
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

        // setup data to store
        bytes memory tokenData_1 = abi.encode("Assembly Press 1");
        bytes memory tokenData_2 = abi.encode("Assembly Press 2");
        bytes[] memory tokenDataArray = new bytes[](2);
        tokenDataArray[0] = tokenData_1;
        tokenDataArray[1] = tokenData_2;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        vm.prank(AP721_ADMIN);
        database.store(newAP721, encodedTokenDataArray);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 2, "tokens not minted to correct recipient");
        bytes[] memory readAllDataReturn = new bytes[](2);
        readAllDataReturn = database.readAllData(newAP721);
        require(keccak256(readAllDataReturn[0]) == keccak256(tokenData_1), "tokenData_1 not stored + read correctly");
        require(keccak256(readAllDataReturn[1]) == keccak256(tokenData_2), "tokenData_2 not stored + read correctly");
    }

    function test_quantityTwo_read() public {
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

        // setup data to store
        bytes memory tokenData_1 = abi.encode("Assembly Press 1");
        bytes memory tokenData_2 = abi.encode("Assembly Press 2");
        bytes[] memory tokenDataArray = new bytes[](2);
        tokenDataArray[0] = tokenData_1;
        tokenDataArray[1] = tokenData_2;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        vm.prank(AP721_ADMIN);
        database.store(newAP721, encodedTokenDataArray);
        bytes[] memory readAllDataReturn = new bytes[](2);
        readAllDataReturn = database.readAllData(newAP721);
        require(keccak256(readAllDataReturn[0]) == keccak256(tokenData_1), "tokenData_1 not stored + read correctly");
        require(keccak256(readAllDataReturn[1]) == keccak256(tokenData_2), "tokenData_2 not stored + read correctly");
    }

    function test_Revert_TargetNotInitialized_store() public {
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

        // setup data to store
        bytes memory tokenData = abi.encode("Assembly Press");
        bytes[] memory tokenDataArray = new bytes[](1);
        tokenDataArray[0] = tokenData;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        // Target not initialized
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        vm.prank(AP721_ADMIN);
        database.store(address(0), encodedTokenDataArray);
    }

    function test_WhatHappensWithEmptyTokenData_store() public {
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

        // setup data to store
        bytes memory tokenData = new bytes(0);
        bytes[] memory tokenDataArray = new bytes[](1);
        tokenDataArray[0] = tokenData;
        bytes memory encodedTokenDataArray = abi.encode(tokenDataArray);
        vm.prank(AP721_ADMIN);
        database.store(newAP721, encodedTokenDataArray);
        require(keccak256(database.readData(newAP721, 1)) == keccak256(tokenData), "data not stored + read correctly");
    }
}

/* 

Execution Paths

questions:
    - figure out if there needs to be a check for mint quantity now that its not a param anymore
        - can someone mess up a row by passing in incorrect data?
            - I think actually protected if you have an implementation that mints same number of slots stored?
    - what happens if you pass in empty bytes data to SSTORE2.write ✅
        - Looks like it still creates an SSTORE2 pointer address and stores it 

`store`    
    - calling permissions determined by logic contract set for given target
    - will revert if
        - target hasn't been initialized yet - TESTED ✅
        - will revert if response of IAP721Logic.logic.`getStore` is false
        - quantity of tokens is greater than uint256? - (unncessary to test) ✅
        - recipient address for tokens (msg.sender) cannot receive ERC721 tokens? 
        - Amount of data passed in triggers running out of gas even if qunatity is less than uint256?
    - must result in
        - X new tokens being minted to msg.sender as determiend by designated quantity - TESTED ✅
    - NOTE: there are no checks on if data is actually being stored "correctly" 
            or even being associated with the tokens that are minted. The base impl
            provides an example for how to do this, but nothing is enforced.
            Should we add a closng function check that AP721 last token minted = ap721Settings.storagerCounter + 1?
                - cant even enforce this ^ so probalby not worth it
    - questions: could potentially revert if storing an enormous amount of data over gas limit?  
*/
