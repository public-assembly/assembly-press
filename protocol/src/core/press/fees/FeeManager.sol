// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {TransferUtils} from "../../../utils/TransferUtils.sol";
import {ISharedErrors} from "../../shared/ISharedErrors.sol";

/**
 * @title FeeManager
 */
contract FeeManager {

    address public immutable feeRecipient;
    uint256 public immutable fee;

    error Fee_Transfer_Failed();
    error Cannot_Set_Recipient_To_Zero_Address();

    constructor (address _feeRecipient, uint256 _fee) {
        feeRecipient = _feeRecipient;
        fee = _fee;
        if (_feeRecipient == address(0)) {
            revert Cannot_Set_Recipient_To_Zero_Address();
        }        
    }

    function getFees(uint256 numStorageSlots) external returns (uint256) {
        return fee * numStorageSlots;
    }

    function _handleFees(uint256 numStorageSlots) internal {
        uint256 totalFee = fee * numStorageSlots;
        if (msg.value != totalFee) revert ISharedErrors.Incorrect_Msg_Value();
        if (!TransferUtils.safeSendETH(
            feeRecipient, 
            totalFee, 
            TransferUtils.FUNDS_SEND_LOW_GAS_LIMIT
        )) revert Fee_Transfer_Failed();
    }
}

