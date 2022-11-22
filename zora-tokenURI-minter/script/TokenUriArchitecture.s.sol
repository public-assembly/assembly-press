// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenUriMetadataRenderer} from "../src/TokenUriMetadataRenderer.sol";
import {TokenUriMinter} from "../src/TokenUriMinter.sol";


contract DeployCore is Script {

    function setUp() public {}

    function run() public {
        
        uint256 mintPrice = 0;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        TokenUriMetadataRenderer renderer = new TokenUriMetadataRenderer();

        new TokenUriMinter(
            mintPrice,
            address(renderer)
        );

        vm.stopBroadcast();
    }
}


// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/TokenUriArchitecture.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/TokenUriArchitecture.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv