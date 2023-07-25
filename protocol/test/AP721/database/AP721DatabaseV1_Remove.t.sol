// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {AP721Config} from "../utils/setup/AP721Config.sol";

import {AP721} from "../../../src/core/token/AP721/nft/AP721.sol";
import {AP721DatabaseV1} from "../../../src/core/token/AP721/database/AP721DatabaseV1.sol";
import {IAP721Database} from "../../../src/core/token/AP721/interfaces/IAP721Database.sol";
import {IAP721} from "../../../src/core/token/AP721/interfaces/IAP721.sol";

import {MockLogic} from "../utils/mocks/logic/MockLogic.sol";
import {MockLogic_OnlyAdmin} from "../utils/mocks/logic/MockLogic_OnlyAdmin.sol";
import {MockRenderer} from "../utils/mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721DatabaseV1_RemoveTest is AP721Config {
    function test_remove() public {
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
        database.store(newAP721, 1, encodedTokenDataArray);

        // setup remove call
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.prank(AP721_ADMIN);
        database.remove(newAP721, tokenIds);
        require(AP721(payable(newAP721)).balanceOf(AP721_ADMIN) == 0, "token not burned correctly");
        // read should revert because token does not exist
        vm.expectRevert(abi.encodeWithSignature("Token_Does_Not_Exist()"));
        database.readData(newAP721, 1);
        bytes[] memory readAllDataReturn = database.readAllData(newAP721);
        require(keccak256(readAllDataReturn[0]) == keccak256(BYTES_ZERO_VALUE), "burned data read incorrectly");
    }

    function test_Revert_TargetNotInitialized_remove() public {
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
        database.store(newAP721, 1, encodedTokenDataArray);

        // setup remove call
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.prank(AP721_ADMIN);
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        database.remove(address(0), tokenIds);
    }

    function test_Revert_NonExistentTokenId_remove() public {
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
        database.store(newAP721, 1, encodedTokenDataArray);

        // setup remove call
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2;
        vm.prank(AP721_ADMIN);
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        database.remove(newAP721, tokenIds);
    }
}

/* 

Execution Paths

`remove`    
    - calling permissions determined by logic contract set for given target
    - will revert if
        - target hasn't been initialized yet - TESTED ✅
        - tokenIds being removed do not exist - TESTED ✅
    - must result in
        - specified tokenIds being burned - TESTED ✅
    - Things to consider POST initial round of testing
        - might make more sense to have the `readAllData` call skip tokens that are burnt,
        and then also just make sure to include assoicated tokenId alongside each chunk of data thats returned
*/
