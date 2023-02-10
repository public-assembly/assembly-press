// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1155Skeleton {

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Amount of existing (minted & not burned) tokens with a given tokenId
    function totalSupply(uint256 tokenId) external view returns (uint256);

    /// @notice getter for internal _numMinted counter which keeps track of quantity minted per tokenId per wallet address
    function numMinted(uint256 tokenId, address account) external view returns (uint256);    

    /// @notice Getter for last minted tokenId
    function tokenCount() external view returns (uint256);

    /// @notice returns true if token type `id` is soulbound
    function isSoulbound(uint256 id) external view returns (bool);
}
