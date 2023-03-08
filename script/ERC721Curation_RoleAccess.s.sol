// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {CurationLogic} from "../src/token/ERC721/Curation/CurationLogic.sol";
import {RoleAccess} from "../src/token/ERC721/Curation/RoleAccess.sol";
import {IERC721PressLogic} from "../src/token/ERC721/interfaces/IERC721PressLogic.sol";
import {IAccessControlRegistry} from "../src/token/ERC721/Curation/IAccessControlRegistry.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        IERC721PressLogic curLogic = new CurationLogic();

        IAccessControlRegistry roleAccess = new RoleAccess();

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC721Curation_RoleAccess.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721Curaiton_RoleAccess.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv