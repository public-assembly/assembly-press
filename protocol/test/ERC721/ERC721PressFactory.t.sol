// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV1} from "../../src/strategies/curation/database/CurationDatabaseV1.sol";
import {ERC721Press} from "../../src/core/token/ERC721/ERC721Press.sol";
import {ERC721PressFactory} from "../../src/core/token/ERC721/ERC721PressFactory.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract ERC721PressFactoryTest is ERC721PressConfig {

    function test_factory() public {
        
        ERC721Press erc721PressImpl = new ERC721Press();
        CurationDatabaseV1 databaseImpl = new CurationDatabaseV1(primaryOwner, secondaryOwner);
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );

        // SETUP LOGIC INIT
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory initialRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](2);
        initialRoles[0].account = PRESS_ADMIN_AND_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = PRESS_MANAGER;
        initialRoles[1].role = MANAGER_ROLE;      
        mockAccessPass.mint(PRESS_USER);   
        bool initialIsPaused = false;     
        bool initialIsTokenDataImmutable = true;     
        bytes memory logicInit = abi.encode(address(mockAccessPass), initialIsPaused, initialIsTokenDataImmutable, initialRoles);

        // SETUP RENDERER INIT
        string memory contractUriImagePath = "ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH";
        bytes memory rendererInit = abi.encode(contractUriImagePath);

        // SETUP DATABASE INIT
        bytes memory databaseInit = abi.encode(
            address(logic),
            logicInit,
            address(renderer),
            rendererInit
        );

        // PRESS SETTINGS
        IERC721Press.Settings memory pressSettings = IERC721Press.Settings({
            fundsRecipient: PRESS_FUNDS_RECIPIENT,
            royaltyBPS: 250, // 2.5%
            transferable: false
        });        

        // Expect revert because factory hasnt been granted official status 
        //      to enable it to allowlist Press contracts to initialize on the database yet
        vm.expectRevert(abi.encodeWithSignature("No_Initialize_Access()"));
        erc721Factory.createPress({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            databaseInit: databaseInit,
            settings: pressSettings,
            optionalPressInit: new bytes(0)      
        });        

        // GRANT FACTORY OFFICIAL STATUS
        vm.startPrank(primaryOwner);
        databaseImpl.setOfficialFactory(address(erc721Factory));
        vm.stopPrank();

        erc721Factory.createPress({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            databaseInit: databaseInit,
            settings: pressSettings,
            optionalPressInit: new bytes(0)      
        });
    }

    function test_gasTest() public {
        
        ERC721Press erc721PressImpl = new ERC721Press();
        CurationDatabaseV1 databaseImpl = new CurationDatabaseV1(primaryOwner, secondaryOwner);
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );

        // SETUP LOGIC INIT
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory initialRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](2);
        initialRoles[0].account = PRESS_ADMIN_AND_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = PRESS_MANAGER;
        initialRoles[1].role = MANAGER_ROLE;      
        mockAccessPass.mint(PRESS_USER);   
        bool initialIsPaused = false;     
        bool initialIsTokenDataImmutable = true;     
        bytes memory logicInit = abi.encode(address(mockAccessPass), initialIsPaused, initialIsTokenDataImmutable, initialRoles);

        // SETUP RENDERER INIT
        string memory contractUriImagePath = "ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH";
        bytes memory rendererInit = abi.encode(contractUriImagePath);

        // SETUP DATABASE INIT
        bytes memory databaseInit = abi.encode(
            address(logic),
            logicInit,
            address(renderer),
            rendererInit
        );

        // PRESS SETTINGS
        IERC721Press.Settings memory pressSettings = IERC721Press.Settings({
            fundsRecipient: PRESS_FUNDS_RECIPIENT,
            royaltyBPS: 250, // 2.5%
            transferable: false
        });            

        // GRANT FACTORY OFFICIAL STATUS
        vm.startPrank(primaryOwner);
        databaseImpl.setOfficialFactory(address(erc721Factory));
        vm.stopPrank();

        erc721Factory.createPress({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            databaseInit: databaseInit,
            settings: pressSettings,
            optionalPressInit: new bytes(0)           
        });        
    }    
}