// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {AP721Config} from "../../utils/setup/AP721Config.sol";

import {AP721} from "../../../../src/core/token/AP721/nft/AP721.sol";
import {AP721DatabaseV1} from "../../../../src/core/token/AP721/database/AP721DatabaseV1.sol";
import {IAP721Database} from "../../../../src/core/token/AP721/interfaces/IAP721Database.sol";
import {IAP721} from "../../../../src/core/token/AP721/interfaces/IAP721.sol";

import {MockLogic} from "../../utils/mocks/logic/MockLogic.sol";
import {MockLogic_OnlyAdmin} from "../../utils/mocks/logic/MockLogic_OnlyAdmin.sol";
import {MockRenderer} from "../../utils/mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721DatabaseV1_StoreBatchTest is AP721Config {
    
    function test_storeBatch() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);

        // setup quantities array
        uint256[] memory quantities = new uint256[](3);
        quantities[0] = 1;
        quantities[1] = 1;
        quantities[2] = 1;

        // setup data to store
        bytes[] memory encodedTokenDataArrays = new bytes[](3);
        {
            bytes memory tokenData_1 = abi.encode("One");
            bytes[] memory tokenDataArray_1 = new bytes[](1);
            tokenDataArray_1[0] = tokenData_1;
            bytes memory tokenData_2 = abi.encode("Two");
            bytes[] memory tokenDataArray_2 = new bytes[](1);
            tokenDataArray_2[0] = tokenData_2;
            bytes memory tokenData_3 = abi.encode("Three");
            bytes[] memory tokenDataArray_3 = new bytes[](1);
            tokenDataArray_3[0] = tokenData_3;                

            encodedTokenDataArrays[0] = abi.encode(tokenDataArray_1);
            encodedTokenDataArrays[1] = abi.encode(tokenDataArray_2);
            encodedTokenDataArrays[2] = abi.encode(tokenDataArray_3);
        }

        address[] memory targets = new address[](3);
        {         
            targets[0] = createAP721(
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
            targets[1] = createAP721(
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
            targets[2] = createAP721(
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
            vm.prank(AP721_ADMIN);
            database.storeBatch(targets, quantities, encodedTokenDataArrays);
        }

        require(AP721(payable(targets[0])).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(AP721(payable(targets[1])).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(AP721(payable(targets[2])).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(keccak256(database.readData(targets[0], 1)) == keccak256(abi.encode("One")), "data not stored + read correctly");
        require(keccak256(database.readData(targets[1], 1)) == keccak256(abi.encode("Two")), "data not stored + read correctly");
        require(keccak256(database.readData(targets[2], 1)) == keccak256(abi.encode("Three")), "data not stored + read correctly");
    }
}
