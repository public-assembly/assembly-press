// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC1155PressGasConfig} from "./utils/ERC1155PressGasConfig.sol";
import {ERC1155BasicContractLogic} from "../../src/token/ERC1155/logic/ERC1155BasicContractLogic.sol";
import {ERC1155Press} from "../../src/token/ERC1155/ERC1155Press.sol";
import {ERC1155PressProxy} from "../../src/token/ERC1155/proxy/ERC1155PressProxy.sol";

contract ERC1155Press_GasTests is ERC1155PressGasConfig {    

    function test_deployAndInitERC1155Press() public {
        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC1155PressProxy(erc1155PressImpl, "")));

        erc1155Press = ERC1155Press(pressProxy);

        // initialize erc1155 contract
        erc1155Press.initialize({
            _name: contractName,
            _symbol: contractSymbol,
            _initialOwner: INITIAL_OWNER,
            _contractLogic: contractLogic,
            _contractLogicInit: contractLogicInit
        });
    }

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

    // function test_batchMintExisting() public {
    //     vm.startPrank(INITIAL_OWNER);
    //     vm.deal(INITIAL_OWNER, 10 ether);
    //     uint256[] memory quants = new uint256[](2);
    //     quants[0] = 1;
    //     quants[1] = 1;
    //     uint256[] memory tokenIds = new uint256[](2);
    //     tokenIds[0] = 1;
    //     tokenIds[1] = 2;
    //     address recipient = address(0x666);
    //     erc1155Press.batchMintExisting{ value: 0.002 ether}(tokenIds, recipient, quants);
    // }

    function test_burn() public {
        vm.startPrank(ADMIN);
        erc1155Press.burn(1, 1);
    }

    function test_batchBurn() public {
        vm.startPrank(ADMIN);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;       
        erc1155Press.batchBurn(tokenIds, amounts);        
    }
}