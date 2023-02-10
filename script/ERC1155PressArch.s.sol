// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC1155Press} from "../src/token/ERC1155/ERC1155Press.sol";
import {ERC1155PressCreatorV1} from "../src/token/ERC1155/ERC1155PressCreatorV1.sol";
import {IERC1155Press} from "../src/token/ERC1155/interfaces/IERC1155Press.sol";
import {ERC1155BasicContractLogic} from "../src/token/ERC1155/logic/ERC1155BasicContractLogic.sol";
import {ERC1155InfiniteArtifactLogic} from "../src/token/ERC1155/logic/ERC1155InfiniteArtifactLogic.sol";
import {ERC1155EditionRenderer} from "../src/token/ERC1155/metadata/ERC1155EditionRenderer.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        IERC1155Press erc1155Press = new ERC1155Press();        

        ERC1155BasicContractLogic contractLogic = new ERC1155BasicContractLogic();

        ERC1155InfiniteArtifactLogic tokenLogic = new ERC1155InfiniteArtifactLogic();

        ERC1155EditionRenderer tokenRenderer = new ERC1155EditionRenderer();

        ERC1155PressCreatorV1 erc1155Creator = new ERC1155PressCreatorV1(
            address(erc1155Press),
            contractLogic,
            tokenLogic,
            tokenRenderer
        );

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC1155PressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv