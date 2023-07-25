// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {IAP721} from "../src/core/token/AP721/interfaces/IAP721.sol";
import {AP721} from "../src/core/token/AP721/nft/AP721.sol";
import {AP721Proxy} from "../src/core/token/AP721/nft/proxy/AP721Proxy.sol";
import {AP721Factory} from "../src/core/token/AP721/factory/AP721Factory.sol";
import {AP721DatabaseV1} from "../src/core/token/AP721/database/AP721DatabaseV1.sol";
import {MockLogic} from "../test/AP721/utils/mocks/logic/MockLogic.sol";
import {MockRenderer} from "../test/AP721/utils/mocks/renderer/MockRenderer.sol";


contract DeployCore is Script {

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        AP721 ap721Impl = new AP721();
        AP721DatabaseV1 database = new AP721DatabaseV1();
        AP721Factory factoryImpl = new AP721Factory(address(payable(ap721Impl)), address(database));
        MockLogic mockLogic = new MockLogic(address(database));
        MockRenderer mockRenderer = new MockRenderer(address(database));

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/AP721Arch.s.sol:DeployCore --rpc-url $OPTIMISM_GOERLI_RPC_URL --broadcast --verify --verifier-url https://api-goerli-optimistic.etherscan.io/
// forge script script/AP721Arch.s.sol:DeployCore --rpc-url $SEPOLIA_RPC_URL --broadcast --verify  -vvvv
// forge script script/AP721Arch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/AP721Arch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv


// --verifier-url https://goerli-optimism.etherscan.io/