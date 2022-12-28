
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IPress {
    
    // ===== TYPES
    struct PressConfig {
        address fundsRecipient;
        uint16 royaltyBPS;
        address logic;
        address renderer;
    }
    
    error CANNOT_SET_ZERO_ADDRESS();
    error CANNOT_MINT();
    error INCORRECT_MSG_VALUE();
    error NO_WITHDRAW_ACCESS();
    error WITHDRAW_FUNDS_SEND_FAILURE();

    // event PublisherInitialized(address publisherAddress);

    function owner() view external returns (address);
    function lastMintedTokenId() external view returns (uint256);
}