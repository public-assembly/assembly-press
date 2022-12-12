// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";

import {SignatureMinter} from "../../src/signature-minter/SignatureMinter.sol";

contract DeployerSignatureMinter is Script {
    function run() external {
        vm.startBroadcast();

        console.log(msg.sender);

        SignatureMinter minter = new SignatureMinter("1");

        console2.log("Deploying SignatureMinter to ", address(minter));

        vm.stopBroadcast();
    }
}
