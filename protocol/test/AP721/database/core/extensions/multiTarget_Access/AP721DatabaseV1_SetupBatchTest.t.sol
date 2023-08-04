// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";

import {AP721Config_Extensions} from "../../../../utils/setup/AP721Config_Extensions.sol";
import {AP721} from "../../../../../../src/core/token/AP721/nft/AP721.sol";
import {ExampleDatabaseV1} from "../../../../../../src/strategies/example/database/ExampleDatabaseV1.sol";
import {IAP721DatabaseMultiTarget} from "../../../../../../src/core/token/AP721/database/interfaces/extensions/IAP721DatabaseMultiTarget.sol";
import {IAP721} from "../../../../../../src/core/token/AP721/nft/interfaces/IAP721.sol";

contract AP721DatabaseV1_SetupBatchTest is AP721Config_Extensions {

    function test_setupAP721Batch() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        bytes memory factoryInit = abi.encode(CONTRACT_NAME, CONTRACT_SYMBOL);
        bytes memory databaseInit = abi.encode(
            address(mockLogic),
            address(mockRenderer),
            NON_TRANSFERABLE,
            adminInit,
            adminInit
        );

        IAP721DatabaseMultiTarget.SetupAP721BatchArgs[] memory setupAP721BatchArgs = new IAP721DatabaseMultiTarget.SetupAP721BatchArgs[](3);    

        setupAP721BatchArgs[0] = IAP721DatabaseMultiTarget.SetupAP721BatchArgs({
            initialOwner: AP721_ADMIN,
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });
        setupAP721BatchArgs[1] = IAP721DatabaseMultiTarget.SetupAP721BatchArgs({
            initialOwner: AP721_ADMIN,
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });
        setupAP721BatchArgs[2] = IAP721DatabaseMultiTarget.SetupAP721BatchArgs({
            initialOwner: AP721_ADMIN,
            databaseInit: databaseInit,
            factory: address(factoryImpl),
            factoryInit: factoryInit
        });                       

        address[] memory newAP721s = database.setupAP721Batch(setupAP721BatchArgs);

        for (uint256 i; i < newAP721s.length; ++i) {
            // Fetch newly initialized database settings
            (IAP721DatabaseMultiTarget.Settings memory settings) = database.getSettings(newAP721s[i]);
            // Initialization tests
            require(
                keccak256(bytes(AP721(payable(newAP721s[i])).name())) == keccak256(bytes(CONTRACT_NAME)), "name set incorrectly"
            );
            require(
                keccak256(bytes(AP721(payable(newAP721s[i])).symbol())) == keccak256(bytes(CONTRACT_SYMBOL)),
                "symbol set incorrectly"
            );            
            require(AP721(payable(newAP721s[i])).owner() == AP721_ADMIN, "owner set incorrectly");
            require(settings.initialized == 1, "initialized flag not set correctly");
            require(settings.logic == address(mockLogic), "logic address set incorrectly");
            require(settings.renderer == address(mockRenderer), "renderer address set incorrectly");
            require(settings.storageCounter == 0, "storage counter should be zero upon initialization");
            require(
                settings.ap721Config.transferable == NON_TRANSFERABLE, "token transferability not initialzied correctly"
            );
            vm.prank(address(database));
            // should revert because newAP721 is an AP721Proxy that should already have been initialized, and cannot be re-initialized
            vm.expectRevert();
            AP721(payable(newAP721s[i])).initialize(address(0), address(0), BYTES_ZERO_VALUE);
        }
    }
}