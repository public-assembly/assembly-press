// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IFundsManager} from "./IFundsManager.sol";
import {TransferUtils} from "./TransferUtils.sol";

/**
* @title FundsManagerBasic
* @notice Facilitates funds routing for ERC721Press primary and secondary sales
* @author Max Bochman
*/
contract FundsManagerBasic is IFundsManager {

    // TYPES
    struct Settings {
        address fundsRecipient;
        uint16 royaltyBPS;
    }

    // STORAGE
    string constant public name = "FUNDS_MANAGER_BASIC";

    // stores payment settings for a given press
    mapping(address => Settings) public paymentSettingsInfo;

    function initializeWithData(bytes calldata data) external {
        // data format: fundsRecipient, royaltyBPS
        (
            address fundsRecipient,
            uint16 royaltyBPS
        ) = abi.decode(data, (address, uint16));

        // save payment settings for a given Press
        paymentSettingsInfo[msg.sender].fundsRecipient = fundsRecipient;
        paymentSettingsInfo[msg.sender].royaltyBPS = royaltyBPS;
    }

    /// @dev Get fundsRecipient information for given Press
    /// @param targetPress targetPress
    function recipientForPress(address targetPress) external view returns (address) {
        return paymentSettingsInfo[targetPress].fundsRecipient;
    }        

    /// @dev Get royalty information for given Press + token
    /// @param targetPress sale price for the token
    /// @param salePrice sale price for the token
    function royaltiesForPress(address targetPress, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        if (paymentSettingsInfo[targetPress].fundsRecipient == address(0)) {
            return (address(0), 0);
        }
        return (
            paymentSettingsInfo[targetPress].fundsRecipient, 
            salePrice * paymentSettingsInfo[targetPress].royaltyBPS / 10_000
        );
    }    
}

// saving unused code originall put into ERC721Press:

// mintWithData call
/*
// Call logic contract to check totalMintPrice for given quantity * sender
if (msgValue != IERC721PressLogic(_logicImpl).totalMintPrice(address(this), quantity, sender)) {
    revert Incorrect_Msg_Value();
}        

// Lookup funds recipient for press and route msg value there
TransferUtils.safeSendETH(
    _fundsManager.recipientForPress(_self), 
    msgValue, 
    TransferUtils._FUNDS_SEND_NORMAL_GAS_LIMIT
);
*/

// setFundsManager calls
/*
    /// @notice sets up the fundsManager contract used by ERC721Press contract
    /// @param fundsManager the fundsManager contract
    /// @param fundsManagerInit the data to initialize fundsManager contract with
    function _setFundsManager(IFundsManager fundsManager, bytes calldata fundsManagerInit) internal {
        _fundsManager = fundsManager;
        _fundsManager.initializeWithData(fundsManagerInit);
        emit FundsManagerUpdated(msg.sender, fundsManager);    
    }     

    /// @notice externally accessible fundsManager setup function
    /// @param fundsManager the fundsManager contract
    /// @param fundsManagerInit the data to initialize fundsManager contract with
    function setFundsManager(IFundsManager fundsManager, bytes calldata fundsManagerInit) external {
        _setFundsManager(fundsManager, fundsManagerInit);
    }        
*/