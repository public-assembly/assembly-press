// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {CustomPricingMinter} from "../src/CustomPricingMinter.sol";

contract DeployCore is Script {

    // ===== CONSTRUCTOR INPUTS =====
    uint256 public nonBundlePricePerToken = 10000000000000000; // 0.01 ETH
    uint256 public bundlePricePerToken = 5000000000000000; // 0.005 ETH
    uint256 public bundleQuantity = 10;  

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

// forge script script/CustomPricingMinter.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv

