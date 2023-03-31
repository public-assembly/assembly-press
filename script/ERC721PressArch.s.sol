// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC721Press} from "../src/token/ERC721/ERC721Press.sol";
import {CurationLogic} from "../src/token/ERC721/curation/logic/CurationLogic.sol";
import {CurationMetadataRenderer} from "../src/token/ERC721/curation/metadata/CurationMetadataRenderer.sol";
import {HybridAccess} from "../src/token/ERC721/curation/access/HybridAccess.sol";
import {ERC721PressFactory} from "../src/token/ERC721/ERC721PressFactory.sol";

import {IERC721PressFactory} from "../src/token/ERC721/core/interfaces/IERC721PressFactory.sol";
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
        
        IERC721PressRenderer curationRenderer = new CurationMetadataRenderer();

        IERC721PressLogic curationLogic = new CurationLogic();

        IAccessControlRegistry hybridAccess = new HybridAccess();        
        
        IERC721PressFactory erc721Factory = new ERC721PressFactory(address(erc721Press));

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC721PressArch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721PressArch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv