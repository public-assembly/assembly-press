// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenUriMetadataRenderer} from "../src/TokenUriMetadataRenderer.sol";
import {TokenUriMinter} from "../src/TokenUriMinter.sol";
import {PACreatorV1} from "../src/PACreatorV1.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // creator proxy address from https://github.com/ourzora/zora-drops-contracts/blob/main/addresses/1.json
        address zoraNFTCreatorProxy = 0xF74B146ce44CC162b601deC3BE331784DB111DC1; // MAINNET
        // address zoraNFTCreatorProxy = 0xb9583D05Ba9ba8f7F14CCEe3Da10D2bc0A72f519; // GOERLI

        vm.startBroadcast(deployerPrivateKey);

        TokenUriMetadataRenderer uriRenderer = new TokenUriMetadataRenderer();

        TokenUriMinter uriMinter = new TokenUriMinter(address(uriRenderer));

        new PACreatorV1(
            zoraNFTCreatorProxy,
            uriRenderer,
            address(uriMinter)
        );

        vm.stopBroadcast();
    }
}


// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/TokenUriArchitecture.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/TokenUriArchitecture.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv