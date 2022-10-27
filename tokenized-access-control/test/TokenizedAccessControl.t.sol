// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {ERC721PresetMinterPauserAutoId} from "openzeppelin-contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {TokenizedAccessControl} from "../src/TokenizedAccessControl.sol";

contract TokenizedAccessControlTest is DSTest {

    // Init Variables
    ERC721PresetMinterPauserAutoId erc721;
    ERC20PresetMinterPauser erc20;
    Vm public constant vm = Vm(HEVM_ADDRESS);
    address payable public constant DEFAULT_OWNER_ADDRESS =
        payable(address(0x999));
    address payable public constant DEFAULT_NON_OWNER_ADDRESS =
        payable(address(0x888));        
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function setUp() public {
        // deploy NFT contract
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721 = new ERC721PresetMinterPauserAutoId("721NAME", "721SYM", "baseURI/");
        erc20 = new ERC20PresetMinterPauser("20NAME", "20SYM");
        vm.stopPrank();
    }

    function test_ManagerRole() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721.mint(DEFAULT_OWNER_ADDRESS);
        erc20.mint(DEFAULT_OWNER_ADDRESS, 100);
        TokenizedAccessControl tAccessControl = new TokenizedAccessControl(
            IERC721(erc721),
            IERC20(erc20),
            0,
            0,
            IERC721(erc721),
            IERC20(erc20),
            0,
            0
        );
        assertTrue(tAccessControl.checkIfManager(DEFAULT_OWNER_ADDRESS));
        assertTrue(!tAccessControl.checkIfManager(DEFAULT_NON_OWNER_ADDRESS));
    }    

    function test_CuratorRole() public {
        vm.startPrank(DEFAULT_OWNER_ADDRESS);
        erc721.mint(DEFAULT_OWNER_ADDRESS);
        erc20.mint(DEFAULT_OWNER_ADDRESS, 100);
        TokenizedAccessControl tAccessControl = new TokenizedAccessControl(
            IERC721(erc721),
            IERC20(erc20),
            0,
            0,
            IERC721(erc721),
            IERC20(erc20),
            0,
            0
        );
        assertTrue(tAccessControl.checkIfCurator(DEFAULT_OWNER_ADDRESS));
        assertTrue(!tAccessControl.checkIfCurator(DEFAULT_NON_OWNER_ADDRESS));
    }       
}