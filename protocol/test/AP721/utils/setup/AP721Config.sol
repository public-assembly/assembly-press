// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IAP721} from "../../../../src/core/token/AP721/interfaces/IAP721.sol";
import {AP721} from "../../../../src/core/token/AP721/nft/AP721.sol";
import {AP721Proxy} from "../../../../src/core/token/AP721/nft/proxy/AP721Proxy.sol";
import {AP721DatabaseV1} from "../../../../src/core/token/AP721/database/AP721DatabaseV1.sol";

import {MockLogic} from "../mocks/MockLogic.sol";
import {MockRenderer} from "../mocks/MockRenderer.sol";


contract AP721Config is Test {

    // ADDRESSES FOR DATABASE OWNERSHIP + OFFICIAL FACTORY
    address public primaryOwner;
    address public secondaryOwner;
    address public mockFactory;
    // ADDRESSES FOR PRESS + PRESS PROXY
    ERC721Press public erc721PressImpl;
    ERC721Press public targetPressProxy;
    // ACTORS + ROLES + ACCESS PASS
    address public constant PRESS_ADMIN_AND_OWNER = address(0x333);
    address public constant PRESS_MANAGER = address(0x222);
    address public constant PRESS_USER = address(0x111);
    address public constant PRESS_NO_ROLE_1 = address(0x001);
    address public constant PRESS_NO_ROLE_2 = address(0x002);
    address payable public constant PRESS_FUNDS_RECIPIENT = payable(address(0x999));
    uint8 public constant ADMIN_ROLE = 3;
    uint8 public constant MANAGER_ROLE = 2;
    uint8 public constant USER = 1;
    uint8 public constant NO_ROLE = 0;        
    MockERC721 public mockAccessPass = new MockERC721();
    // DATABASE + LOGIC + RENDERER SETUP
    CurationDatabaseV1 internal database = new CurationDatabaseV1(primaryOwner, secondaryOwner);
    MockDatabase public mockDatabase = new MockDatabase(primaryOwner, secondaryOwner);
    RolesWith721GateImmutableMetadataNoFees public logic = new RolesWith721GateImmutableMetadataNoFees();
    CurationRendererV1 public renderer = new CurationRendererV1();
    TokenGateFeeModule public feeModule = new TokenGateFeeModule(address(0), 0, address(0));

    // Gets run before every test 
    function setUp() public {

    }
}

// 