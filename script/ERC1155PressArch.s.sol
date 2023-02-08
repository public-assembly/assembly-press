// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC1155Press} from "../src/token/ERC1155/ERC1155Press.sol";
import {IERC1155Press} from "../src/token/ERC1155/interfaces/IERC1155Press.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        IERC1155Press erc1155Press = new ERC1155Press();

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv