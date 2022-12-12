// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DefaultMetadataDecoder} from "../src/DefaultMetadataDecoder.sol";
import {Publisher} from "../src/Publisher.sol";
import {AssemblyPress} from "../src/AssemblyPress.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address editionMetadataRendererAddressGoerli = 0x2f5C21EF9DdFf9A1FE76a1c55dd5112fcf2EfD39;

        // creator proxy address from https://github.com/ourzora/zora-drops-contracts/blob/main/addresses/1.json
        // address zoraNFTCreatorProxy = 0xF74B146ce44CC162b601deC3BE331784DB111DC1; // MAINNET
        address zoraNFTCreatorProxy = 0xb9583D05Ba9ba8f7F14CCEe3Da10D2bc0A72f519; // GOERLI

        vm.startBroadcast(deployerPrivateKey);

        Publisher publisher = new Publisher();

        new DefaultMetadataDecoder();        

        new AssemblyPress(
            zoraNFTCreatorProxy,
            editionMetadataRendererAddressGoerli,
            publisher
        );

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/AssemblyPressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/AssemblyPressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv