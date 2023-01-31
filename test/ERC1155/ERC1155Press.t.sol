// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC1155PressConfig} from "./utils/ERC1155PressConfig.sol";
import {ERC1155BasicContractLogic} from "../../src/token/ERC1155/logic/ERC1155BasicContractLogic.sol";

contract ERC1155PressTest is ERC1155PressConfig {

    function test_Init() public setUpERC1155PressBase {

        // check to see if contract level storage was initialized correctly
        string memory name = erc1155Press.name();
        string memory symbol = erc1155Press.symbol();
        require(keccak256(bytes(name)) == keccak256(bytes(contractName)));
        require(keccak256(bytes(symbol)) == keccak256(bytes(contractSymbol)));        
        require(erc1155Press.owner() == INITIAL_OWNER, "Default owner set wrong");
        require(erc1155Press.contractLogic() == contractLogic, "Contract logic set wrong");

        // check to make sure contract cant be reinitialized
        vm.expectRevert("Initializable: contract is already initialized");
        erc1155Press.initialize({
            _name: contractName,
            _symbol: contractSymbol,
            _initialOwner: INITIAL_OWNER,
            _contractLogic: contractLogic,
            _contractLogicInit: contractLogicInit
        });        

        // check to see if contract logic was initialized correctly
        uint16 accessRole = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),contractAdminInit);
        (uint256 mintNewPrice, uint8 initialized) = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).contractInfo(address(erc1155Press));
        require(accessRole == 2, "admin role was set wrong");
        require(mintNewPrice == 0.01 ether, "mintprice is wrong");
        require(initialized == 1, "initialized is wrong");

        // check to see if contract logic interface works correctly
        vm.startPrank(MINTER);
        uint256 mintQuantity = 3;
        address[] memory minters = new address[](1);
        minters[0] = MINTER;
        require(
            erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                msg.sender,
                minters,
                mintQuantity
            ) == (mintNewPrice * mintQuantity), "mintNewPrice incorrect:"
        );

        // /// @notice checks if a certain address can access mintnew functionality for a given Press + recepients + quantity combination
        // function canMintNew(address targetPress, address mintCaller, address[] memory recipients, uint256 quantities) external view returns (bool);    
        // /// @notice checks if a certain address can transfer ownership of a given Press
        // function canTransferOwnership(address targetPress, address transferCaller) external view returns (bool);    
        // /// @notice checks if a certain address can upgrade the underlying implementation for a given Press
        // function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);    

        // // Informative view functions
        // /// @notice checks if a given Press has been initialized    
        // function isInitialized(address targetPress) external view returns (bool);  

    }
}