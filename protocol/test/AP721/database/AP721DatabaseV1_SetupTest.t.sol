// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {AP721Config} from "../utils/setup/AP721Config.sol";

import {AP721} from "../../../src/core/token/AP721/nft/AP721.sol";
import {IAP721Database} from "../../../src/core/token/AP721/database/interfaces/IAP721Database.sol";

import {MockLogic} from "../utils/mocks/logic/MockLogic.sol";
import {MockRenderer} from "../utils/mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721DatabaseV1_SetupTest is AP721Config {

    function test_setupAP721() public {
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
        // Fetch newly initialized database settings
        (IAP721Database.Settings memory settings) = database.getSettings(newAP721);
        // Initialization tests
        require(
            keccak256(bytes(AP721(payable(newAP721)).name())) == keccak256(bytes(CONTRACT_NAME)), "name set incorrectly"
        );
        require(
            keccak256(bytes(AP721(payable(newAP721)).symbol())) == keccak256(bytes(CONTRACT_SYMBOL)),
            "symbol set incorrectly"
        );
        require(AP721(payable(newAP721)).owner() == AP721_ADMIN, "owner set incorrectly");
        require(settings.initialized == 1, "initialized flag not set correctly");
        require(settings.logic == address(mockLogic), "logic address set incorrectly");
        require(settings.renderer == address(mockRenderer), "renderer address set incorrectly");
        require(settings.storageCounter == 0, "storage counter should be zero upon initialization");
        require(
            settings.ap721Config.transferable == NON_TRANSFERABLE, "token transferability not initialzied correctly"
        );
        require(
            settings.ap721Config.fundsRecipient == address(0),
            "fundsRecipient should be zero because is not set in this database impl"
        );
        require(
            settings.ap721Config.royaltyBPS == 0, "royaltyBPS should be zero because is not set in this database impl"
        );
        vm.prank(address(database));
        // should revert because newAP721 is an AP721Proxy that should already have been initialized, and cannot be re-initialized
        vm.expectRevert();
        AP721(payable(newAP721)).initialize(address(0), address(0), BYTES_ZERO_VALUE);
    }

    function test_Revert_UnauthorizedDatabase_setupAP721() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        // expect revert because factoryImpl uses a different databaseImpl than the one that will call it
        vm.expectRevert(abi.encodeWithSignature("Msg_Sender_Not_Database()"));
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(invalidFactoryImpl),
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );
    }

    function test_Revert_InvalidFactoryImpl_setupAP721() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        // expect revert because factoryImpl is missing necessary functions to initialize ap721
        vm.expectRevert();
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(0x999), // this address isnt a factory impl with necessary functions
            address(mockLogic),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );
    }

    function test_Revert_InvalidLogicImpl_setupAP721() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        // expect revert because logicImpl is missing necessary functions to be initialized
        vm.expectRevert();
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(0x999), // logicImpl
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );
    }

    function test_Revert_InvalidRendererImpl_setupAP721() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // create new ap721
        // expect revert because rendererImpl is missing necessary functions to be initialized
        vm.expectRevert();
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(0x999), // rendererImpl
            adminInit,
            NON_TRANSFERABLE
        );
    }

    /* SET LOGIC + RENDERER TESTS */

    function test_setLogic() public {
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
        // Deploy new logic impl at different address
        MockLogic newLogic = new MockLogic(address(database));
        vm.prank(AP721_ADMIN);
        database.setLogic(newAP721, address(newLogic), adminInit);
        // Fetch newly initialized database settings
        (IAP721Database.Settings memory settings) = database.getSettings(newAP721);
        require(settings.logic == address(newLogic), "logic address set incorrectly");
    }

    function test_Revert_TargetNotInitialized_setLogic() public {
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

        vm.prank(AP721_ADMIN);
        // expect revert because address(0) is not a target that has been initialized
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        database.setLogic(address(0), address(mockLogic), adminInit);
    }

    function test_Revert_InvalidImplementation_setLogic() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // expect revert because logicImpl is missing necessary functions to be initialized
        vm.expectRevert();
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(0),
            adminInit,
            address(mockRenderer),
            adminInit,
            NON_TRANSFERABLE
        );
    }

    function test_setRenderer() public {
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
        // Deploy new logic impl at different address
        MockRenderer newRenderer = new MockRenderer(address(database));
        vm.prank(AP721_ADMIN);
        database.setRenderer(newAP721, address(newRenderer), adminInit);
        // Fetch newly initialized database settings
        (IAP721Database.Settings memory settings) = database.getSettings(newAP721);
        require(settings.renderer == address(newRenderer), "renderer address set incorrectly");
    }

    function test_Revert_TargetNotInitialized_setRenderer() public {
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

        vm.prank(AP721_ADMIN);
        // expect revert because address(0) is not a target that has been initialized
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        database.setRenderer(address(0), address(mockRenderer), adminInit);
    }

    function test_Revert_InvalidImplementation_setRenderer() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        // expect revert because logicImpl is missing necessary functions to be initialized
        vm.expectRevert();
        // create new ap721
        address newAP721 = createAP721(
            CONTRACT_NAME,
            CONTRACT_SYMBOL,
            AP721_ADMIN,
            address(factoryImpl),
            address(mockLogic),
            adminInit,
            address(address(0)),
            adminInit,
            NON_TRANSFERABLE
        );
    }
}

/*  

Execution Paths

`setupNewAP721`
    - anyone can call
    - will revert if
        - invalid inputs are sent
            - factory address doesnt match IAP721Factory interface (`create` specifically) - TESTED ✅
            - logic addres doesnt match IAP721Logic interface (`initializeWithData` specifically) - TESTED ✅
            - renderer addres doesnt match IAP721Renderer interface (`initializeWithData` specifically) - TESTED ✅
            - database address is different than one set in factory impl - TESTED ✅
    - must result in
        - new AP721Proxy created + UUPS initialized
        - new AP721Proxy address initialized in ap721Settings mapping
        - logic contract set in ap721Settings mapping - TESTED ✅
            - and initialized with data if applicable
        - renderer contract set in ap721Settings mapping - TESTED ✅
            - and initialized with data if applicable       
        - return the address of new AP721Proxy
`setLogic`    
    - calling permissions determined by logic contract set for given target
    - will revert if
        - target hasn't been initialized yet - TESTED ✅
        - msg.sender doesnt have permissions to update logic impl
        - logic address doesnt match IAP721Logic interface (`initializeWithData` specifically) - TESTED ✅
    - must result in
        - techincally nothing
`setRenderer`    
    - calling permissions determined by renderer contract set for given target
    - will revert if
        - target hasn't been initialized yet - TESTED ✅
        - msg.sender doesnt have permissions to update renderer impl
        - renderer address doesnt match IAP721Renderer interface (`initializeWithData` specifically) - TESTED ✅
    - must result in
        - techincally nothing        
*/
