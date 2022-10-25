// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CustomPricingMinter} from "../src/CustomPricingMinter.sol";

contract DeployCore is Script {

    // ===== CONSTRUCTOR INPUTS =====
    uint256 public nonBundlePricePerToken = 22000000000000000; // 0.022 ETH
    uint256 public bundlePricePerToken = 10000000000000000; // 0.01 ETH (.01 * 22 = 0.22 full bundle price)
    uint256 public bundleQuantity = 22;  

    function setUp() public {}

    function run() public {
        

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        new CustomPricingMinter(
            nonBundlePricePerToken,
            bundlePricePerToken,
            bundleQuantity
        );
        
        vm.stopBroadcast();
    }
}


// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/CustomPricingMinter.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/CustomPricingMinter.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv

