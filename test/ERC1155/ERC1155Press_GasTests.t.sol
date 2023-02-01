// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC1155PressGasConfig} from "./utils/ERC1155PressGasConfig.sol";
import {ERC1155BasicContractLogic} from "../../src/token/ERC1155/logic/ERC1155BasicContractLogic.sol";

contract ERC1155Press_GasTests is ERC1155PressGasConfig {    

    function test_mintNew() public {    
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory mintNewRecipients = new address[](1);
        mintNewRecipients[0] = ADMIN;
        uint256 quantity = 1;
        address payable fundsRecipient = payable(ADMIN);
        uint16 royaltyBPS = 10_00; // 10%
        address payable primarySaleFeeRecipient = payable(MINTER);
        uint16 primarySaleFeeBPS = 5_00; // 5%
        bool soulbound = false;
        erc1155Press.mintNew{
            value: 0.01 ether 
        }(
            mintNewRecipients,
            quantity,
            tokenLogic,
            tokenLogicInit,
            basicRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulbound
        );
    }

    function test_mintExisting() public {        
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory recips = new address[](1);
        recips[0] = address(0x666);
        uint256 quant = 1;
        erc1155Press.mintExisting{ value: 0.001 ether}(1, recips, quant);      
    }    

}