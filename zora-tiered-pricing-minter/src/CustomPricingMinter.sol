// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ERC721DropMinterInterface} from "./ERC721DropMinterInterface.sol";

/**
 * @notice Adds custom pricing tier logic to standard ZORA Drop contracts
 * @dev Only compatible with ZORA Drop contracts that inherit ERC721Drop
 * @author max@ourzora.com
 *
 */

contract CustomPricingMinter is Ownable, ReentrancyGuard {
    // ===== ERRORS =====
    /// @notice Action is unable to complete because msg.value is incorrect
    error WrongPrice();

    /// @notice Action is unable to complete because minter contract has not recieved minting role
    error MinterNotAuthorized();

    /// @notice Funds transfer not successful to drops contract
    error TransferNotSuccessful();

    // ===== EVENTS =====
    /// @notice mint with quantity below bundle cutoff has occurred
    event NonBundleMint(address minter, uint256 quantity, uint256 totalPrice);

    /// @notice mint with quantity at or above bundle cutoff has occurred
    event BundleMint(address minter, uint256 quantity, uint256 totalPrice);

    /// @notice nonBundle price per token has been updated
    event NonBundlePricePerTokenUpdated(address owner, uint256 newPrice);

    /// @notice bundle price per token has been updated
    event BundlePricePerTokenUpdated(address owner, uint256 newPrice);

    /// @notice bundleQuantity cutoff has been updated
    event BundleQuantityUpdated(address owner, uint256 newQuantity);

    // ===== CONSTANTS =====
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");
    bytes32 public immutable DEFAULT_ADMIN_ROLE = 0x00;
    uint256 public immutable FUNDS_SEND_GAS_LIMIT = 300_000;

    // ===== PUBLIC VARIABLES =====
    uint256 public nonBundlePricePerToken;
    uint256 public bundlePricePerToken;
    uint256 public bundleQuantity;

    // ===== CONSTRUCTOR =====
    constructor(
        uint256 _nonBundlePricePerToken,
        uint256 _bundlePricePerToken,
        uint256 _bundleQuantity
    ) {
        nonBundlePricePerToken = _nonBundlePricePerToken;
        bundlePricePerToken = _bundlePricePerToken;
        bundleQuantity = _bundleQuantity;
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***      PUBLIC MINTING FUNCTIONS      ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev calls nonBundle or bundle mint function depending on quantity entered
    /// @param zoraDrop ZORA Drop contract to mint from
    /// @param mintRecipient address to recieve minted tokens
    /// @param quantity number of tokens to mint
    function flexibleMint(
        address zoraDrop,
        address mintRecipient,
        uint256 quantity
    ) external payable nonReentrant returns (uint256) {
        // check if CustomPricingMinter contract has MINTER_ROLE on target ZORA Drop contract
        if (
            !ERC721DropMinterInterface(zoraDrop).hasRole(
                MINTER_ROLE,
                address(this)
            )
        ) {
            revert MinterNotAuthorized();
        }

        // check if mint quantity is below bundleQuantity cutoff
        if (quantity < bundleQuantity) {
            // check if total mint price is correct for nonBundle quantities
            if (msg.value != quantity * nonBundlePricePerToken) {
                revert WrongPrice();
            }

            _nonBundleMint(zoraDrop, mintRecipient, quantity);

            // Transfer funds to zora drop contract
            (bool nonBundleSuccess, ) = zoraDrop.call{value: msg.value}("");
            if (!nonBundleSuccess) {
                revert TransferNotSuccessful();
            }            

            return quantity;
        }

        // check if total mint price is correct for bundle quantities
        if (msg.value != quantity * bundlePricePerToken) {
            revert WrongPrice();
        }

        _bundleMint(zoraDrop, mintRecipient, quantity);

        // Transfer funds to zora drop contract
        (bool bundleSuccess, ) = zoraDrop.call{value: msg.value}("");
        if (!bundleSuccess) {
            revert TransferNotSuccessful();
        }

        return quantity;
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***     INTERNAL MINTING FUNCTIONS     ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    function _nonBundleMint(
        address zoraDrop,
        address mintRecipient,
        uint256 quantity
    ) internal {
        // call admintMint function on target ZORA contract
        ERC721DropMinterInterface(zoraDrop).adminMint(mintRecipient, quantity);
        emit NonBundleMint(
            msg.sender,
            quantity,
            quantity * nonBundlePricePerToken
        );
    }

    function _bundleMint(
        address zoraDrop,
        address mintRecipient,
        uint256 quantity
    ) internal {
        // call admintMint function on target ZORA contract
        ERC721DropMinterInterface(zoraDrop).adminMint(mintRecipient, quantity);
        emit NonBundleMint(
            msg.sender,
            quantity,
            quantity * bundlePricePerToken
        );
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***          ADMIN FUNCTIONS           ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    /// @dev updates nonBundlePricePerToken variable
    /// @param newPrice new nonBundlePricePerToken value
    function setNonBundlePricePerToken(uint256 newPrice) public onlyOwner {
        nonBundlePricePerToken = newPrice;

        emit NonBundlePricePerTokenUpdated(msg.sender, newPrice);
    }

    /// @dev updates bundlePricePerToken variable
    /// @param newPrice new bundlePricePerToken value
    function setBundlePricePerToken(uint256 newPrice) public onlyOwner {
        bundlePricePerToken = newPrice;

        emit BundlePricePerTokenUpdated(msg.sender, newPrice);
    }

    /// @dev updates bundleQuantity variable
    /// @param newQuantity new bundleQuantity value
    function setBundleQuantity(uint256 newQuantity) public onlyOwner {
        bundleQuantity = newQuantity;

        emit BundleQuantityUpdated(msg.sender, newQuantity);
    }

    /**
     *** ---------------------------------- ***
     ***                                    ***
     ***           VIEW FUNCTIONS           ***
     ***                                    ***
     *** ---------------------------------- ***
     ***/

    function fullBundlePrice() external view returns (uint256) {
        return bundlePricePerToken * bundleQuantity;
    }
}
