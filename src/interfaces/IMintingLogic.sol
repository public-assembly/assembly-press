
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {} from "";

interface IMintingLogic {
    // error CantSet_ZeroAddress();

    // event PublisherInitialized(address publisherAddress);

    // function initialize(address _initialOwner) external returns (address);

    function canMint(address addressToCheck) view external returns (bool);
    function 
}