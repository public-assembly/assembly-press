
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IMetadataRenderer} from "./IMetadataRenderer.sol";
import {IMintingLogic} from "./IMintingLogic.sol";
import {IAccessControl} from "./IMetadataRenderer.sol";

interface IPress is IMetadataRenderer, IMintingLogic, IAccessControl  {
    
    // ===== TYPES
    struct PressConfig {
        address metadataRenderer;
        address mintingLogic;
        address accessControl;
    }
    
    // error CantSet_ZeroAddress();

    // event PublisherInitialized(address publisherAddress);

    function owner() view external returns (address);
}