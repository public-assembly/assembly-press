// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC1155TokenRenderer} from "./interfaces/IERC1155TokenRenderer.sol";
import {IERC1155PressContractLogic} from "./interfaces/IERC1155PressContractLogic.sol";
import {IERC1155PressTokenLogic} from "./interfaces/IERC1155PressTokenLogic.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";
import {IERC1155Press} from "./interfaces/IERC1155Press.sol";

/**
 * @title ERC1155PressPermissions
 * @notice Permission calls used in ERC1155Press
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155PressPermissions is ERC1155PressStorageV1 {

    function _canMintNew(address targetPress, address sender, address[] memory recipients, uint256 quantity) internal view {
        // Call contract level logic contract to check if user can mint
        if (!IERC1155PressContractLogic(contractLogic).canMintNew(targetPress, sender, recipients, quantity)) {
            revert IERC1155Press.No_MintNew_Access();
        }     
    }

    // Call logic contract to check what msg.value needs to be sent
    function _mintNewValueCheck(uint256 msgValue, address targetPress, address sender, address[] memory recipients, uint256 quantity) internal view {
        if (msgValue != IERC1155PressContractLogic(contractLogic).mintNewPrice(targetPress, sender, recipients, quantity)) {
            revert IERC1155Press.Incorrect_Msg_Value();
        }
    }

    // Call token level logic contract to check if user can mint
    function _canMintExisting(address targetPress, address sender, uint256 tokenId, address[] memory recipients, uint256 quantity) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canMintExisting(targetPress, sender, tokenId, recipients, quantity)) {
            revert IERC1155Press.No_MintExisting_Access();
        }           
    } 

    // Call logic contract to check what msg.value needs to be sent
    function _mintExistingValueCheck(uint256 msgValue, address targetPress, uint256 tokenId, address sender, address[] memory recipients, uint256 quantity) internal view {
        if (msgValue != IERC1155PressTokenLogic(configInfo[tokenId].logic).mintExistingPrice(targetPress, tokenId, sender, recipients, quantity)) {
            revert IERC1155Press.Incorrect_Msg_Value();
        }
    }

    // Call logic contract to check if burn is allowed for sender
    function _canBurn(address targetPress, uint256 tokenId, uint256 amount, address sender) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canBurn(targetPress, tokenId, amount, sender)) {
            revert IERC1155Press.No_Burn_Access();
        }   
    }

    // Call logic contract to check is msg.sender can update
    function _canUpdateConfig(address targetPress, uint256 tokenId, address sender) internal view {
        if (!IERC1155PressTokenLogic(configInfo[tokenId].logic).canUpdateConfig(targetPress, tokenId, sender)) {
            revert IERC1155Press.No_Config_Access();
        }    
    }    

    // Call logic contract to check if withdraw is allowed for sender
    function _canWithdraw(address targetPress, uint256 tokenId, address sender) internal view {
        if (IERC1155PressTokenLogic(configInfo[tokenId].logic).canWithdraw(targetPress, tokenId, sender) != true) {
            revert IERC1155Press.No_Withdraw_Access();
        }    
    }    
    // call logic contract to check is msg.sender can upgrade
    function _canUpgrade(address targetPress, address sender) internal view {
        if (!IERC1155PressContractLogic(contractLogic).canUpgrade(targetPress, sender)) {
            revert IERC1155Press.No_Upgrade_Access();
        }    
    }
}