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

    // Gets run before every test 
    function setUp() public {

    }
}

// 