// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC1155Press} from "../src/token/ERC1155/ERC1155Press.sol";
import {ERC1155PressFactory} from "../src/token/ERC1155/ERC1155PressFactory.sol";
import {ERC1155PressFactoryProxy} from "../src/token/ERC1155/core/proxy/ERC1155PressFactoryProxy.sol";
import {IERC1155Press} from "../src/token/ERC1155/core/interfaces/IERC1155Press.sol";
import {ERC1155EditionContractLogic} from "../src/token/ERC1155/strategies/editions/logic/ERC1155EditionContractLogic.sol";
import {ERC1155EditionTokenLogic} from "../src/token/ERC1155/strategies/editions/logic/ERC1155EditionTokenLogic.sol";
import {ERC1155EditionRenderer} from "../src/token/ERC1155/strategies/editions/metadata/ERC1155EditionRenderer.sol";

contract DeployCore is Script {

    address paTreasuryAddress = 0x8330E78222619FD26A9FBCbEbAeb21339838bD30;
    address secondaryOwnerAddress = 0xE7746f79bF98e685e6a1ac80D74d2935431041d5;

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        IERC1155Press erc1155Press = new ERC1155Press();        

        // ERC1155EditionContractLogic contractLogic = new ERC1155EditionContractLogic();

        // ERC1155EditionTokenLogic tokenLogic = new ERC1155EditionTokenLogic();

        // ERC1155EditionRenderer tokenRenderer = new ERC1155EditionRenderer();

        ERC1155PressFactory erc1155Factory = new ERC1155PressFactory(address(erc1155Press));

        ERC1155PressFactoryProxy factoryProxy = new ERC1155PressFactoryProxy(address(erc1155Factory), paTreasuryAddress, secondaryOwnerAddress);

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $SEPOLIA_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv