// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IPublisher} from "./interfaces/IPublisher.sol";

/**
 @notice Publisher.sol storage variables contract
 @author Max Bochman
 */
contract PublisherStorage is IPublisher {

    /// @notice zora drops contracts immutable minter_role storage
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");

    /// @notice mintPricePerToken storage
    mapping(address => uint256) public mintPricePerToken;
    
    // zora collection => access control module in use
    mapping(address => address) public dropAccessControl; 

    /// @notice ContractURI mapping storage
    mapping(address => string) public contractURIInfo;

    /// @notice zora collection -> tokenId -> {tokenRenderer, tokenMetadata}
    mapping(address => mapping(uint256 => ArtifactDetails)) public artifactInfo;     

    // /// @notice Storage gap
    // uint256[49] __gap;
}
