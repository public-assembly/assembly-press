// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IChannelTypesV1} from "../types/IChannelTypesV1.sol";

interface IChannel {
    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    /// @notice Error when msg.sender is not the stored database impl
    error Sender_Not_River();
    // /// @notice Error when attempting to transfer non-transferrable token
    // error Non_Transferrable_Token();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Initializes a ChannelProxy
    function initialize(        
        string memory channelName, 
        address initialOwner,
        address riverImpl,
        address feeRouterImpl,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit,
        IChannelTypesV1.AdvancedSettings memory advancedSettings
    ) external;
    function store(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory);

    // /// @notice Batch-mint tokens to a designated recipient
    // function mint(address recipient, uint256 quantity) external;
    // /// @notice Burn specific tokenId. Reduces totalSupply
    // function burn(uint256 tokenId) external;
    // /// @notice Burn multiple tokenIds. Reduces totalSupply
    // function burnBatch(uint256[] memory tokenIds) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    // /// @notice Getter for AP721 owner
    // function owner() external view returns (address);
    // /// @notice Contract uri getter
    // function contractURI() external view returns (string memory);
    // /// @notice Token uri getter
    // function uri() external view returns (string memory);    
    // /// @dev Get royalty information for token
    // /// @param _tokenId the NFT asset queried for royalty information
    // /// @param _salePrice the sale price of the NFT asset specified by _tokenId
    // function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    //     external
    //     view
    //     returns (address receiver, uint256 royaltyAmount);
    // /// @notice ERC165 supports interface
    // /// @param interfaceId interface id to check if supported
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
