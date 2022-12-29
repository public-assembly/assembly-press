
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPress {
    
    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    struct PressConfig {
        address payable fundsRecipient;
        uint16 royaltyBPS;
        address logic;
        address renderer;
    }

    struct PrimarySaleFee {
        address payable feeRecipient;
        uint16 feeBPS;
    }    

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Function to return the press config details for the given press
    function pressConfigDetails() external view returns (PressConfig memory);

    function owner() view external returns (address);
    function lastMintedTokenId() external view returns (uint256);    

    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Event emitted when the funds are withdrawn from the minting contract
    /// @param withdrawnBy address that issued the withdraw
    /// @param withdrawnTo address that the funds were withdrawn to
    /// @param amount amount that was withdrawn
    /// @param feeRecipient user getting withdraw fee (if any)
    /// @param feeAmount amount of the fee getting sent (if any)
    event FundsWithdrawn(
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount,
        address feeRecipient,
        uint256 feeAmount
    );    
    
    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // |||||||||||||||||||||||||||||||| 

    /// @notice Royalty percentage too high
    error Setup_RoyaltyPercentageTooHigh(uint16 maxRoyaltyBPS);
    /// @notice Cannot withdraw funds due to ETH send failure
    error Withdraw_FundsSendFailure();

    error SET_PRESS_CONFIG_FAIL();
    error CANNOT_SET_ZERO_ADDRESS();
    error CANNOT_MINT();
    error INCORRECT_MSG_VALUE();
    error NO_WITHDRAW_ACCESS();
    error WITHDRAW_FUNDS_SEND_FAILURE();
    error NO_UPGRADE_ACCESS();
    error NO_UPDATE_ACCESS();
    error ONLY_OWNER_ACCESS();
    error NO_BURN_ACCESS();
}