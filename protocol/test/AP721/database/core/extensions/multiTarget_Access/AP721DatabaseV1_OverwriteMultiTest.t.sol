// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";

import {AP721Config_Extensions} from "../../../../utils/setup/AP721Config_Extensions.sol";
import {AP721} from "../../../../../../src/core/token/AP721/nft/AP721.sol";
import {ExampleDatabaseV1} from "../../../../../../src/strategies/example/database/ExampleDatabaseV1.sol";
import {IAP721DatabaseMultiTarget} from "../../../../../../src/core/token/AP721/database/interfaces/extensions/IAP721DatabaseMultiTarget.sol";
import {IAP721} from "../../../../../../src/core/token/AP721/nft/interfaces/IAP721.sol";


contract AP721DatabaseV1_OverwriteMultiTest is AP721Config_Extensions {
    
    function test_overwriteMulti() public {
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

        // setup data for overwriteMulti call
        bytes[][] memory encodedOverwriteTokenDataArrays = new bytes[][](3);
        {
            bytes memory overwriteTokenData_1 = abi.encode("OverwriteOne");
            bytes[] memory overwriteTokenDataArray_1 = new bytes[](1);
            overwriteTokenDataArray_1[0] = overwriteTokenData_1;
            bytes memory overwriteTokenData_2 = abi.encode("OverwriteTwo");
            bytes[] memory overwriteTokenDataArray_2 = new bytes[](1);
            overwriteTokenDataArray_2[0] = overwriteTokenData_2;
            bytes memory overwriteTokenData_3 = abi.encode("OverwriteThree");
            bytes[] memory overwriteTokenDataArray_3 = new bytes[](1);
            overwriteTokenDataArray_3[0] = overwriteTokenData_3;                

            encodedOverwriteTokenDataArrays[0] = overwriteTokenDataArray_1;
            encodedOverwriteTokenDataArrays[1] = overwriteTokenDataArray_2;
            encodedOverwriteTokenDataArrays[2] = overwriteTokenDataArray_3;
        }        

        // setup args for overwriteMulti call
        IAP721DatabaseMultiTarget.OverwriteMultiArgs[] memory overwriteMultiArgs = new IAP721DatabaseMultiTarget.OverwriteMultiArgs[](3);
        {
            uint256[] memory overwriteTokenIdArray = new uint256[](1);
            overwriteTokenIdArray[0] = 1;

            overwriteMultiArgs[0] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[0],
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[0]
            });
            overwriteMultiArgs[1] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[1],
                tokenIds: overwriteTokenIdArray,                
                data: encodedOverwriteTokenDataArrays[1]
            });
            overwriteMultiArgs[2] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[2],
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[2]
            });                            
        }          
        vm.prank(AP721_ADMIN);
        database.overwriteMulti(overwriteMultiArgs);      

        require(keccak256(database.readData(storeMultiArgs[0].target, 1)) == keccak256(abi.encode("OverwriteOne")), "data not overwritten + read correctly");
        require(keccak256(database.readData(storeMultiArgs[1].target, 1)) == keccak256(abi.encode("OverwriteTwo")), "data not overwritten + read correctly");
        require(keccak256(database.readData(storeMultiArgs[2].target, 1)) == keccak256(abi.encode("OverwriteThree")), "data not overwritten + read correctly");
    }

    function test_Revert_NoOverwriteAccess_overwriteMulti() public {
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

        // setup data for overwriteMulti call
        bytes[][] memory encodedOverwriteTokenDataArrays = new bytes[][](3);
        {
            bytes memory overwriteTokenData_1 = abi.encode("OverwriteOne");
            bytes[] memory overwriteTokenDataArray_1 = new bytes[](1);
            overwriteTokenDataArray_1[0] = overwriteTokenData_1;
            bytes memory overwriteTokenData_2 = abi.encode("OverwriteTwo");
            bytes[] memory overwriteTokenDataArray_2 = new bytes[](1);
            overwriteTokenDataArray_2[0] = overwriteTokenData_2;
            bytes memory overwriteTokenData_3 = abi.encode("OverwriteThree");
            bytes[] memory overwriteTokenDataArray_3 = new bytes[](1);
            overwriteTokenDataArray_3[0] = overwriteTokenData_3;                

            encodedOverwriteTokenDataArrays[0] = overwriteTokenDataArray_1;
            encodedOverwriteTokenDataArrays[1] = overwriteTokenDataArray_2;
            encodedOverwriteTokenDataArrays[2] = overwriteTokenDataArray_3;
        }        

        // setup args for overwriteMulti call
        IAP721DatabaseMultiTarget.OverwriteMultiArgs[] memory overwriteMultiArgs = new IAP721DatabaseMultiTarget.OverwriteMultiArgs[](3);
        {
            uint256[] memory overwriteTokenIdArray = new uint256[](1);
            overwriteTokenIdArray[0] = 1;

            overwriteMultiArgs[0] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[0],
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[0]
            });
            overwriteMultiArgs[1] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[1],
                tokenIds: overwriteTokenIdArray,                
                data: encodedOverwriteTokenDataArrays[1]
            });
            overwriteMultiArgs[2] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[2],
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[2]
            });                            
        }          

        vm.prank(address(0x666));
        vm.expectRevert(abi.encodeWithSignature("No_Overwrite_Access()"));
        database.overwriteMulti(overwriteMultiArgs);      
    }    

    function test_Revert_TargetNotInitialized_overwriteMulti() public {
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

        // setup data for overwriteMulti call
        bytes[][] memory encodedOverwriteTokenDataArrays = new bytes[][](3);
        {
            bytes memory overwriteTokenData_1 = abi.encode("OverwriteOne");
            bytes[] memory overwriteTokenDataArray_1 = new bytes[](1);
            overwriteTokenDataArray_1[0] = overwriteTokenData_1;
            bytes memory overwriteTokenData_2 = abi.encode("OverwriteTwo");
            bytes[] memory overwriteTokenDataArray_2 = new bytes[](1);
            overwriteTokenDataArray_2[0] = overwriteTokenData_2;
            bytes memory overwriteTokenData_3 = abi.encode("OverwriteThree");
            bytes[] memory overwriteTokenDataArray_3 = new bytes[](1);
            overwriteTokenDataArray_3[0] = overwriteTokenData_3;                

            encodedOverwriteTokenDataArrays[0] = overwriteTokenDataArray_1;
            encodedOverwriteTokenDataArrays[1] = overwriteTokenDataArray_2;
            encodedOverwriteTokenDataArrays[2] = overwriteTokenDataArray_3;
        }        

        // setup args for overwriteMulti call
        IAP721DatabaseMultiTarget.OverwriteMultiArgs[] memory overwriteMultiArgs = new IAP721DatabaseMultiTarget.OverwriteMultiArgs[](3);
        {
            uint256[] memory overwriteTokenIdArray = new uint256[](1);
            overwriteTokenIdArray[0] = 1;

            overwriteMultiArgs[0] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[0],
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[0]
            });
            overwriteMultiArgs[1] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                target: newAP721s[1],
                tokenIds: overwriteTokenIdArray,                
                data: encodedOverwriteTokenDataArrays[1]
            });
            overwriteMultiArgs[2] = IAP721DatabaseMultiTarget.OverwriteMultiArgs({
                /* ERROR INSERTED HERE */
                /* ERROR INSERTED HERE */
                /* ERROR INSERTED HERE */
                target: address(0x666),
                tokenIds: overwriteTokenIdArray,
                data: encodedOverwriteTokenDataArrays[2]
            });                            
        }          

        vm.prank(address(AP721_ADMIN));
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        database.overwriteMulti(overwriteMultiArgs);      
    }        
}
