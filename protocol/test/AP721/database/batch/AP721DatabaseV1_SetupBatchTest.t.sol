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

contract AP721DatabaseV1_SetupBatchTest is AP721Config {

    // NOTE: must run test with --via-ir enabled to avoid stack too deep errors

    function test_setupAP721Batch() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        bytes memory factoryInit = abi.encode(CONTRACT_NAME, CONTRACT_SYMBOL);
        bytes memory databaseInit = abi.encode(address(mockLogic), address(mockRenderer), false, adminInit, adminInit);

        AP721DatabaseV1.SetupAP721BatchArgs[] memory setupAP721BatchArgs = new AP721DatabaseV1.SetupAP721BatchArgs[](3);    

        setupAP721BatchArgs[0] = AP721DatabaseV1.SetupAP721BatchArgs({
            initialOwner: address(0x1),
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });
        setupAP721BatchArgs[1] = AP721DatabaseV1.SetupAP721BatchArgs({
            initialOwner: address(0x2),
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });
        setupAP721BatchArgs[2] = AP721DatabaseV1.SetupAP721BatchArgs({
            initialOwner: address(0x3),
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });                             

        address[] memory newAP721s = database.setupAP721Batch(setupAP721BatchArgs);

        for (uint256 i; i < newAP721s.length; ++i) {
            vm.prank(address(database));
            // should revert because newAP721 is an AP721Proxy that should already have been initialized, and cannot be re-initialized
            vm.expectRevert();
            AP721(payable(newAP721s[i])).initialize(address(0), address(0), BYTES_ZERO_VALUE);
        }
    }
}