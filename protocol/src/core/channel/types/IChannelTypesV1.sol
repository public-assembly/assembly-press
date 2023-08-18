// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IChannelTypesV1 {
    struct AdvancedSettings {
        /// @notice        
        address fundsRecipient;
        /// @notice        
        uint16 royaltyBPS;
        /// @notice        
        bool transferable;
        /// @notice
        bool fungible;
    }

    struct Settings {
        /// @notice Counter for token storage
        uint256 counter;
        /// @notice Address of the logic contract
        address logic;
        /// @notice Address of the renderer contract
        address renderer;
        /// Stores advanced settings for channel
        AdvancedSettings advancedSettings;        
    }    
}