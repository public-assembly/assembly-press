// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC721PressEngine} from "../interfaces/IERC721PressEngine.sol";

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

interface IERC721Press {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @param fundsRecipient Address that receives funds from sale
    /// @param royaltyBPS BPS of the royalty set on the contract. Can be 0 for no royalty
    /// @param transferable Whether or not tokens from this contract can be transferred
    struct Settings {
        address payable fundsRecipient;
        uint16 royaltyBPS;
        bool transferable;
    }

    // 
    event ERC721PressInitialized();

    /// @notice Event emitted when engine address is updated
    /// @param sender address that sent update txn
    /// @param engine new engine address
    event EngineUpdated(
        address indexed sender,
        IERC721PressEngine engine
    );             

    /// @notice Event emitted when settings are updated
    /// @param sender address that sent update txn
    /// @param settings new settings
    event SettingsUpdated(
        address indexed sender,
        Settings settings
    );            


    // ||||||||||||||||||||||||||||||||
    // ||| ERROS ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have mint access for given Press
    error No_Mint_Access();
    /// @notice msg.sender does not have burn access for given Press
    error No_Burn_Access();    
    /// @notice msg.sender does not have sort access for given Press
    error No_Sort_Access();            
    /// @notice msg.sender does not have settings access for given Press
    error No_Settings_Access();
    /// @notice msg.sender does not have withdraw access for given Press
    error No_Withdraw_Access();    


    // Constraint & failure errors
    /// @notice Royalty percentage too high
    error Royalty_Percentage_Too_High(uint16 bps);    

}