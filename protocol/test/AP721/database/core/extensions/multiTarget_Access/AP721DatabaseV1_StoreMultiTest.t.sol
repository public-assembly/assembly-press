// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";

import {AP721Config_Extensions} from "../../../../utils/setup/AP721Config_Extensions.sol";
import {AP721} from "../../../../../../src/core/token/AP721/nft/AP721.sol";
import {ExampleDatabaseV1} from "../../../../../../src/strategies/example/database/ExampleDatabaseV1.sol";
import {IAP721DatabaseMultiTarget} from "../../../../../../src/core/token/AP721/database/interfaces/extensions/IAP721DatabaseMultiTarget.sol";
import {IAP721} from "../../../../../../src/core/token/AP721/nft/interfaces/IAP721.sol";


contract AP721DatabaseV1_StoreMultiTest is AP721Config_Extensions {
    
    function test_storeMulti() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        bytes memory factoryInit = abi.encode(CONTRACT_NAME, CONTRACT_SYMBOL);
        bytes memory databaseInit = abi.encode(
            address(mockLogicAccess_OnlyAdmin),
            address(mockRenderer),
            NON_TRANSFERABLE,
            adminInit,
            adminInit
        );        

        // Setup args for setupAP721Batch call
        IAP721DatabaseMultiTarget.SetupAP721BatchArgs[] memory setupAP721BatchArgs = new IAP721DatabaseMultiTarget.SetupAP721BatchArgs[](3);   
        {
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
        }             
        address[] memory newAP721s = database.setupAP721Batch(setupAP721BatchArgs);

        // setup data for storeMulti call
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

        // setup args for storeMulti call
        IAP721DatabaseMultiTarget.StoreMultiArgs[] memory storeMultiArgs = new IAP721DatabaseMultiTarget.StoreMultiArgs[](3);     
        {
            storeMultiArgs[0] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[0],
                data: encodedTokenDataArrays[0]
            });
            storeMultiArgs[1] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[1],
                data: encodedTokenDataArrays[1]
            });
            storeMultiArgs[2] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[2],
                data: encodedTokenDataArrays[2]
            });                            
        }      
        vm.prank(AP721_ADMIN);
        database.storeMulti(storeMultiArgs);      

        require(AP721(payable(storeMultiArgs[0].target)).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(AP721(payable(storeMultiArgs[1].target)).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(AP721(payable(storeMultiArgs[2].target)).balanceOf(AP721_ADMIN) == 1, "tokens not minted to correct recipient");
        require(keccak256(database.readData(storeMultiArgs[0].target, 1)) == keccak256(abi.encode("One")), "data not stored + read correctly");
        require(keccak256(database.readData(storeMultiArgs[1].target, 1)) == keccak256(abi.encode("Two")), "data not stored + read correctly");
        require(keccak256(database.readData(storeMultiArgs[2].target, 1)) == keccak256(abi.encode("Three")), "data not stored + read correctly");
    }

    function test_Revert_NoStoreAccess_storeMulti() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        bytes memory factoryInit = abi.encode(CONTRACT_NAME, CONTRACT_SYMBOL);
        bytes memory databaseInit = abi.encode(
            address(mockLogicAccess_OnlyAdmin),
            address(mockRenderer),
            NON_TRANSFERABLE,
            adminInit,
            adminInit
        );        

        // Setup args for setupAP721Batch call
        IAP721DatabaseMultiTarget.SetupAP721BatchArgs[] memory setupAP721BatchArgs = new IAP721DatabaseMultiTarget.SetupAP721BatchArgs[](3);   
        {
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
        }             
        address[] memory newAP721s = database.setupAP721Batch(setupAP721BatchArgs);

        // setup data for storeMulti call
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

        // setup args for storeMulti call
        IAP721DatabaseMultiTarget.StoreMultiArgs[] memory storeMultiArgs = new IAP721DatabaseMultiTarget.StoreMultiArgs[](3);     
        {
            storeMultiArgs[0] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[0],
                data: encodedTokenDataArrays[0]
            });
            storeMultiArgs[1] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[1],
                data: encodedTokenDataArrays[1]
            });
            storeMultiArgs[2] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[2],
                data: encodedTokenDataArrays[2]
            });                            
        }      

        vm.prank(address(0x666));
        vm.expectRevert(abi.encodeWithSignature("No_Store_Access()"));
        database.storeMulti(storeMultiArgs);      
    }    

    function test_Revert_TargetNotInitialized_storeMulti() public {
        // setup logic + renderer inits
        bytes memory adminInit = abi.encode(AP721_ADMIN);
        bytes memory factoryInit = abi.encode(CONTRACT_NAME, CONTRACT_SYMBOL);
        bytes memory databaseInit = abi.encode(
            address(mockLogicAccess_OnlyAdmin),
            address(mockRenderer),
            NON_TRANSFERABLE,
            adminInit,
            adminInit
        );        

        // Setup args for setupAP721Batch call
        IAP721DatabaseMultiTarget.SetupAP721BatchArgs[] memory setupAP721BatchArgs = new IAP721DatabaseMultiTarget.SetupAP721BatchArgs[](3);   
        {
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
        }             
        address[] memory newAP721s = database.setupAP721Batch(setupAP721BatchArgs);

        // setup data for storeMulti call
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

        // setup args for storeMulti call
        IAP721DatabaseMultiTarget.StoreMultiArgs[] memory storeMultiArgs = new IAP721DatabaseMultiTarget.StoreMultiArgs[](3);     
        {
            storeMultiArgs[0] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[0],
                data: encodedTokenDataArrays[0]
            });
            storeMultiArgs[1] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: newAP721s[1],
                data: encodedTokenDataArrays[1]
            });
            storeMultiArgs[2] = IAP721DatabaseMultiTarget.StoreMultiArgs({
                target: address(0x666),
                data: encodedTokenDataArrays[2]
            });                            
        }      

        vm.prank(AP721_ADMIN);
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        database.storeMulti(storeMultiArgs);      
    }        
}
