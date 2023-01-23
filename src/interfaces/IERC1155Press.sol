// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ILogic} from "./ILogic.sol";
import {IRenderer} from "./IRenderer.sol";

interface IERC1155Press {


    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||
    /// @notice msg.sender does not have mint new access for given Press
    error No_MintNew_Access();    
    
    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    struct Configuration {
        address payable fundsRecipient;
        address logic;
        address renderer;
    }

    struct PrimarySaleFee {
        address payable feeRecipient;
        uint16 feeBPS;
    }
}