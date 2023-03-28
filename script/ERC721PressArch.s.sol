// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC721Press} from "../src/token/ERC721/ERC721Press.sol";
import {CurationLogic} from "../src/token/ERC721/curation/logic/CurationLogic.sol";
import {CurationMetadataRenderer} from "../src/token/ERC721/curation/metadata/CurationMetadataRenderer.sol";
import {OpenAccess} from "../src/token/ERC721/curation/access/OpenAccess.sol";
import {ERC721PressCreatorV1} from "../src/token/ERC721/ERC721PressCreatorV1.sol";

import {IERC721PressCreatorV1} from "../src/token/ERC721/core/interfaces/IERC721PressCreatorV1.sol";
import {IERC721PressLogic} from "../src/token/ERC721/core/interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../src/token/ERC721/core/interfaces/IERC721PressRenderer.sol";
import {IERC721Press} from "../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {IAccessControlRegistry} from "../lib/onchain/remote-access-control/src/interfaces/IAccessControlRegistry.sol";

contract DeployCore is Script {

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        IERC721Press erc721Press = new ERC721Press();

        IERC721PressLogic curLogic = new CurationLogic();

        IERC721PressRenderer curRenderer = new CurationMetadataRenderer();

        IAccessControlRegistry openAccess = new OpenAccess();

        IERC721PressCreatorV1 erc721Creator = new ERC721PressCreatorV1(
            address(erc721Press),
            curLogic,
            curRenderer,
            address(openAccess)
        );

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC721PressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721PressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv