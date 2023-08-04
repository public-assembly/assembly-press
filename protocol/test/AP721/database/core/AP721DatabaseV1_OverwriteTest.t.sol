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

contract AP721DatabaseV1_OverwriteTest is AP721Config {
    function test_overwrite() public {
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

        // setup data to overwrite
        bytes memory overwriteData = abi.encode("Public Assembly");
        bytes[] memory overWriteDataArray = new bytes[](1);
        overWriteDataArray[0] = overwriteData;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.prank(AP721_ADMIN);
        database.overwrite(newAP721, tokenIds, overWriteDataArray);
        require(keccak256(database.readData(newAP721, 1)) == keccak256(overwriteData), "data not overwritten correctly");
    }

    function test_Revert_TargetNotInitialized_overwrite() public {
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

        // setup data to overwrite
        bytes memory overwriteData = abi.encode("Public Assembly");
        bytes[] memory overWriteDataArray = new bytes[](1);
        overWriteDataArray[0] = overwriteData;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        vm.expectRevert(abi.encodeWithSignature("Target_Not_Initialized()"));
        vm.prank(AP721_ADMIN);
        database.overwrite(address(0), tokenIds, overWriteDataArray);
    }

    function test_Revert_InputMismatch_overwrite() public {
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

        // setup data to overwrite
        bytes memory overwriteData = abi.encode("Public Assembly");
        bytes[] memory overWriteDataArray = new bytes[](2);
        overWriteDataArray[0] = overwriteData;
        overWriteDataArray[1] = overwriteData;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        // data array longer than tokenId array mismatch
        vm.expectRevert(abi.encodeWithSignature("Invalid_Input_Length()"));
        vm.prank(AP721_ADMIN);
        database.overwrite(newAP721, tokenIds, overWriteDataArray);

        // data array shorter than tokenId array mismatch
        bytes[] memory overWriteDataArray_2 = new bytes[](1);
        overWriteDataArray_2[0] = overwriteData;
        uint256[] memory tokenIds_2 = new uint256[](2);
        tokenIds_2[0] = 1;
        tokenIds_2[1] = 2;
        vm.expectRevert(abi.encodeWithSignature("Invalid_Input_Length()"));
        vm.prank(AP721_ADMIN);
        database.overwrite(newAP721, tokenIds_2, overWriteDataArray_2);

        // data array same length as tokenId array but tokenIds_2[1] dooesnt exist
        // there isnt a named revert for this?
        // NOTE should be Token_Does_Not_Exist reverT?
        vm.expectRevert();
        vm.prank(AP721_ADMIN);
        database.overwrite(newAP721, tokenIds_2, overWriteDataArray);
    }

    function test_Revert_NonExistentTokenId_overwrite() public {
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

        // setup data to overwrite
        bytes memory overwriteData = abi.encode("Public Assembly");
        bytes[] memory overWriteDataArray = new bytes[](1);
        overWriteDataArray[0] = overwriteData;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 2;
        vm.expectRevert(abi.encodeWithSignature("Token_Does_Not_Exist()"));
        vm.prank(AP721_ADMIN);
        database.overwrite(newAP721, tokenIds, overWriteDataArray);
    }
}

/* 

Execution Paths

`overwrite`    
    - calling permissions determined by logic contract set for given target
    - will revert if
        - target hasn't been initialized yet - TESTED ✅
        - mismatch betwen tokenIds.length + data.length - TESTED ✅
        - tokenId being overwritten does not exist - TESTED ✅
    - must result in
        - newly created sstoer2 datapointer - TESTED ✅
            - what happens if you overrwrite with empty data?
                - looks like it just stores an sstore address pointer that points to empty bytes value
    - questions: could potentially revert if storing an enormous amount of data over gas limit?
`remove`    
    - calling permissions determined by logic contract set for given target
    - will revert if
        - target hasn't been initialized yet
        - tokenIds being removed do not exist 
    - must result in
        - specified tokenIds being burned      
*/
