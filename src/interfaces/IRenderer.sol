// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IRenderer {
    // error CantSet_ZeroAddress();

    // event PublisherInitialized(address publisherAddress);

    // function initialize(address _initialOwner) external returns (address);

    function initializeWithData(bytes memory rendererInit) external;
    function initializeTokenMetadata(bytes memory artifactMetadataInit) external ;
    function updateContractURI(address targetPress, string memory newContractURI) external;
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    
}