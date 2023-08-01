// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IAP721} from "../../../../src/core/token/AP721/interfaces/IAP721.sol";
import {AP721} from "../../../../src/core/token/AP721/nft/AP721.sol";
import {AP721Proxy} from "../../../../src/core/token/AP721/nft/proxy/AP721Proxy.sol";
import {AP721Factory} from "../../../../src/core/token/AP721/factory/AP721Factory.sol";
import {AP721DatabaseV2} from "../../../../src/core/token/AP721/database/AP721DatabaseV2.sol";

import {MockLogic} from "../mocks/logic/MockLogic.sol";
import {MockLogic_OnlyAdmin} from "../mocks/logic/MockLogic_OnlyAdmin.sol";
import {MockRenderer} from "../mocks/renderer/MockRenderer.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract AP721Config_2 is Test {
    // AP721 Init Args
    string constant CONTRACT_NAME = "Name";
    string constant CONTRACT_SYMBOL = "SYMBOL";
    bool constant NON_TRANSFERABLE = false;
    bool constant TRANSFERABLE = true;
    // AP721 Global contracts
    AP721DatabaseV2 database;
    AP721Factory factoryImpl;
    AP721Factory invalidFactoryImpl;
    AP721 ap721Impl;
    MockLogic mockLogic;
    MockLogic_OnlyAdmin mockLogic_OnlyAdmin;
    MockRenderer mockRenderer;
    // ACTORS
    address constant AP721_ADMIN = address(0x123);
    // Other constants
    bytes BYTES_ZERO_VALUE = new bytes(0);

    // Set up called before each test
    function setUp() public virtual {
        ap721Impl = new AP721();
        database = new AP721DatabaseV2();
        factoryImpl = new AP721Factory(address(payable(ap721Impl)), address(database));
        invalidFactoryImpl = new AP721Factory(address(payable(ap721Impl)), address(0x666));
        mockLogic = new MockLogic(address(database));
        mockLogic_OnlyAdmin = new MockLogic_OnlyAdmin(address(database));
        mockRenderer = new MockRenderer(address(database));
    }

    function createAP721(
        string memory name,
        string memory symbol,
        address initialOwner,
        address factory,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit,
        bool tokenTransferability
    ) public virtual returns (address) {
        // Setup inits
        bytes memory factoryInit = abi.encode(name, symbol);
        bytes memory databaseInit = abi.encode(logic, renderer, tokenTransferability, logicInit, rendererInit);

        // return address of newly setup AP721
        return database.setupAP721(initialOwner, databaseInit, factory, factoryInit);
    }
}
