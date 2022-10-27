// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {TokenizedAccessControl} from "../src/TokenizedAccessControl.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {
        

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new TokenizedAccessControl(
            IERC721(0x4006b3E4fECBe2f0075F53515c73481B1b023b03), // PA Curation Pass
            IERC20(0xb24cd494faE4C180A89975F1328Eab2a7D5d8f11), // $CODE
            0,
            0,
            IERC721(0x4006b3E4fECBe2f0075F53515c73481B1b023b03), // PA Curation  Pass
            IERC20(0x35bD01FC9d6D5D81CA9E055Db88Dc49aa2c699A8), // $FWB
            0,
            0
        );        

        vm.stopBroadcast();
    }
}


// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/CustomPricingMinter.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/CustomPricingMinter.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv

