
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {} from "";

interface IMetadataRenderer {
    // error CantSet_ZeroAddress();

    // event PublisherInitialized(address publisherAddress);

    // function initialize(address _initialOwner) external returns (address);

    function initializeWithData(bytes memory rendererInit);
    function initializeTokenMetadata(bytes memory artifactMetadataInit);
    function updateContractURI(string memory newContractURI);
    
}