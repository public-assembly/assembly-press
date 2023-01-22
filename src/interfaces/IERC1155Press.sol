// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ILogic} from "./ILogic.sol";
import {IRenderer} from "./IRenderer.sol";

interface IERC1155Press {
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