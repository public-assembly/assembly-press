// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "../utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV1} from "../../../src/strategies/curation/database/CurationDatabaseV1.sol";
import {ERC721Press} from "../../../src/core/token/ERC721/ERC721Press.sol";
import {ERC721PressFactory} from "../../../src/core/token/ERC721/ERC721PressFactory.sol";
import {IERC5192} from "../../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";

import {MockERC721} from "../utils/mocks/MockERC721.sol";
import {MockRenderer} from "../utils/mocks/MockRenderer.sol";
import {MockLogic} from "../utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AddNewFactoriesTest is ERC721PressConfig {  

    function test_databaseSetup() public {
        primaryOwner = address(0x111);
        secondaryOwner = address(0x222);
        ERC721Press erc721PressImpl = new ERC721Press();
        CurationDatabaseV1 databaseImpl = new CurationDatabaseV1(primaryOwner, secondaryOwner);
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );        
        // GRANT FACTORY OFFICIAL STATUS
        vm.startPrank(primaryOwner);
        databaseImpl.setOfficialFactory(address(erc721Factory));
        databaseImpl.isOfficialFactory(address(erc721Factory));
        vm.stopPrank();
        vm.startPrank(address(erc721Factory));
        require(databaseImpl.isOfficialFactory(address(erc721Factory)) == true, "factory not officialized correctly");
        databaseImpl.initializePress(address(erc721Factory));
        // run data storage testes
        bytes memory invalidData = abi.encode("this is invalid data");
        // this should revert because trying to store invalid format data for CurationDatabaseV1
        vm.expectRevert();
        databaseImpl.storeData(address(erc721Factory), invalidData);        
        bytes memory zeroValue = new bytes(0);
        // this should revert because trying to store empty data for CurationDatabaseV1        
        vm.expectRevert();
        databaseImpl.storeData(address(erc721Factory), zeroValue);
        // TODO: add examples of data not reverting because its using valid data
        //
        //
        //
        //
        //        
    }

    function test_addMultipleFactories() public {
        primaryOwner = address(0x111);
        secondaryOwner = address(0x222);
        ERC721Press erc721PressImpl = new ERC721Press();
        CurationDatabaseV1 databaseImpl = new CurationDatabaseV1(primaryOwner, secondaryOwner);
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );        
        // GRANT FACTORY OFFICIAL STATUS
        vm.startPrank(primaryOwner);
        databaseImpl.setOfficialFactory(address(erc721Factory));
        databaseImpl.isOfficialFactory(address(erc721Factory));
        vm.stopPrank();
        vm.startPrank(address(erc721Factory));
        require(databaseImpl.isOfficialFactory(address(erc721Factory)) == true, "factory not officialized correctly");
        bytes[] memory testDataArray =  new bytes[](1);
        testDataArray[0] = abi.encode("this is just a test");
        bytes memory encodedArray = abi.encode(testDataArray);
        databaseImpl.initializePress(address(erc721Factory));
        // this should revert because trying to store invalid data for CurationDatabaseV1           
        vm.expectRevert();
        databaseImpl.storeData(address(erc721Factory), encodedArray);
        vm.stopPrank();
        vm.startPrank(secondaryOwner);
        ERC721PressFactory newFactory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );                
        databaseImpl.setOfficialFactory(address(newFactory));
        require(databaseImpl.isOfficialFactory(address(newFactory)) == true, "factory not officialized correctly");
        vm.stopPrank();
        vm.startPrank(address(newFactory));
        databaseImpl.initializePress(address(newFactory));
        // this should revert because trying to store invalid data for CurationDatabaseV1      
        vm.expectRevert();  
        databaseImpl.storeData(address(newFactory), encodedArray);        
        // TODO: add examples of data not reverting because its using valid data
        //
        //
        //
        //
        //
    }    
}