// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFundsManager {
    
    function name() external view returns (string memory);    
    function initializeWithData(bytes calldata) external;
    function recipientForPress(address targetPress) 
        external view returns (address fundsRecipient);
    function royaltiesForPress(address targetPress, uint256 salePrice) 
        external view returns (address receiver, uint256 royaltyAmount);
}