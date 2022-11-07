// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {ERC721AccessControl} from "../src/ERC721AccessControl.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {
        

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new ERC721AccessControl();       

        vm.stopBroadcast();
    }
}


// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC721AccessControl.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721AccessControl.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv

