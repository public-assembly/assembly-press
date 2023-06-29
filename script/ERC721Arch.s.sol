// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

import {ERC721Press} from "../src/core/token/ERC721/ERC721Press.sol";
import {ERC721PressFactory} from "../src/core/token/ERC721/ERC721PressFactory.sol";
import {ERC721PressDatabaseV1} from "../src/core/token/ERC721/database/ERC721PressDatabaseV1.sol";
import {RolesWith721GateImmutableMetadataNoFees} from "../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationMetadataRenderer} from "../src/strategies/curation/renderer/CurationMetadataRenderer.sol";

contract DeployCore is Script {

    address primaryOwnerAddress = 0x153D2A196dc8f1F6b9Aa87241864B3e4d4FEc170;
    address secondaryOwnerAddress = 0xc5Fe7016bdc0B777FBCBfa9B3Ad99bf3C6789191;

    function setUp() public {}

    function run() public {

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);        

        ERC721Press erc721Press = new ERC721Press();

        RolesWith721GateImmutableMetadataNoFees logic = new RolesWith721GateImmutableMetadataNoFees();

        CurationMetadataRenderer renderer = new CurationMetadataRenderer();

        ERC721PressDatabaseV1 database = new ERC721PressDatabaseV1(primaryOwnerAddress, secondaryOwnerAddress);

        ERC721PressFactory erc721PressFactory = new ERC721PressFactory(address(erc721Press), address(database));

        vm.stopBroadcast();
    }
}

// ======= DEPLOY SCRIPTS =====

// source .env
// forge script script/ERC721Arch.s.sol:DeployCore --rpc-url $SEPOLIA_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721Arch.s.sol:DeployCore --rpc-url $GOERLI_RPC_URL --broadcast --verify  -vvvv
// forge script script/ERC721Arch.s.sol:DeployCore --rpc-url $MAINNET_RPC_URL --broadcast --verify  -vvvv