// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";


import {Router} from "../src/core/router/Router.sol";
import {Factory} from "../src/core/factory/Factory.sol";
import {IFactory} from "../src/core/factory/interfaces/IFactory.sol";
import {Press} from "../src/core/press/Press.sol";
import {PressProxy} from "../src/core/press/proxy/PressProxy.sol";
import {IPress} from "../src/core/press/interfaces/IPress.sol";
import {IPressTypesV1} from "../src/core/press/types/IPressTypesV1.sol";
import {MockLogic} from "../test/mocks/logic/MockLogic.sol";
import {MockRenderer} from "../test/mocks/renderer/MockRenderer.sol";


contract DeployCore is Script {

    Router router;
    Factory factory;
    Press press;
    address feeRecipient;
    uint256 fee;
    MockLogic logic;
    MockRenderer renderer;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        feeRecipient = address(0x999);
        fee = 0.0005 ether;    

        router = new Router();
        press = new Press(feeRecipient, fee);
        factory = new Factory(address(router), address(press));
        logic = new MockLogic();
        renderer = new MockRenderer();
        
        address[] memory factoryToRegister = new address[](1);
        factoryToRegister[0] = address(factory);
        bool[] memory statusToRegister = new bool[](1);
        statusToRegister[0] = true;        
        router.registerFactories(factoryToRegister, statusToRegister);

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/APDeploy.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify
// forge script script/APDeploy.s.sol:DeployCore -vvvv --rpc-url $RPC_URL --broadcast --verify --verifier-url {block exploerer verifier url}

// optimism goerli verifier url https://api-goerli-optimistic.etherscan.io/api