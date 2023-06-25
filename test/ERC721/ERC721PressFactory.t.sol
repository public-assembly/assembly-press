// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721PressDatabaseV1} from "../../src/core/token/ERC721/database/ERC721PressDatabaseV1.sol";
import {ERC721PressFactory} from "../../src/core/token/ERC721/ERC721PressFactory.sol";
import {ERC721Press} from "../../src/core/token/ERC721/ERC721Press.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationMetadataRenderer} from "../../src/strategies/curation/renderer/CurationMetadataRenderer.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract ERC721PressFactory is ERC721PressConfig {

    function setUp () public {

    }

    
    function test_factory() public {
        
        ERC721Press erc721PressImpl = new ERC721Press();
        ERC721PressDatabaseV1 databaseImpl = new ERC721PressDatabaseV1();
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            databaseImpl
        );

        // TODO: 
        // set up inputs for factory in this local set up function

        erc721Factory.createPress({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            databaseInit: databaseInit,
            settings: pressSettings      
        });
    }
}