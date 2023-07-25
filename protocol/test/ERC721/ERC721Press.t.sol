// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV1} from "../../src/strategies/curation/database/CurationDatabaseV1.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from
    "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationRendererV1} from "../../src/strategies/curation/renderer/CurationRendererV1.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {BytesLib} from "solidity-bytes-utils/BytesLib.sol";

contract ERC721PressTest is ERC721PressConfig {
    function test_initialize() public setUpCurationStrategy {
        // testing local press storage
        require(keccak256(bytes(targetPressProxy.name())) == keccak256(bytes("Public Assembly")), "incorrect name");
        require(keccak256(bytes(targetPressProxy.symbol())) == keccak256(bytes("PA")), "incorrect symbol");
        require(targetPressProxy.getDatabase() == database, "incorrect database");
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");
        require(pressSettings.transferable == false, "token transferability set incorrectly");

        // check to see if supportsInterface work
        require(targetPressProxy.supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support");
        require(targetPressProxy.supportsInterface(type(IERC5192).interfaceId) == true, "doesn't support");

        // check to make sure contract cant be reinitialized
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        targetPressProxy.initialize({
            name: "THIS SHOULDNT WORK",
            symbol: "TSW",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            database: database,
            databaseInit: bytes("123"),
            settings: pressSettings
        });
    }

    function test_mint_1_WithData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 1, "mint not functioning correctly");
    }

    function test_mint_2_WithData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](2);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        listings[1].chainId = 7777777;
        listings[1].tokenId = 0;
        listings[1].listingAddress = address(0x54321);
        listings[1].hasTokenId = 0;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(2, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 2, "mint not functioning correctly");
    }

    function test_mintWithMaliciousData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        bytes[] memory encodedListings = new bytes[](2);
        encodedListings[0] = abi.encode(5);
        encodedListings[1] = abi.encode(8);
        bytes memory encodedEncodedListings = abi.encode(encodedListings);
        // should revert because data being passed does not fit Listing struct
        vm.expectRevert();
        targetPressProxy.mintWithData(2, encodedEncodedListings);
    }

    function test_overwrite() public setUpCurationStrategy_MutableMetadata {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory initialTokenData = new CurationDatabaseV1.Listing[](2);
        initialTokenData[0].chainId = 1;
        initialTokenData[0].tokenId = 3;
        initialTokenData[0].listingAddress = address(0x12345);
        initialTokenData[0].hasTokenId = 1;
        initialTokenData[1].chainId = 7777777;
        initialTokenData[1].tokenId = 0;
        initialTokenData[1].listingAddress = address(0x54321);
        initialTokenData[1].hasTokenId = 0;
        bytes memory initialEncodedListings = encodeListingArray(initialTokenData);
        targetPressProxy.mintWithData(2, initialEncodedListings);

        (bytes[] memory initialDatabaseReturn) = database.readAllData(address(targetPressProxy));

        // require(keccak256(initialDatabaseReturn[0].storedData) == keccak256(abi.encode(initialTokenData[0].chainId, initialTokenData[0].tokenId, initialTokenData[0].listingAddress, initialTokenData[0].hasTokenId)), "token #1 data stored incorrectly");
        // require(keccak256(initialDatabaseReturn[1].storedData) == keccak256(abi.encode(initialTokenData[1].chainId, initialTokenData[1].tokenId, initialTokenData[1].listingAddress, initialTokenData[1].hasTokenId)), "token #2 data stored incorrectly");

        string memory tokenURI_1_initial = targetPressProxy.tokenURI(1);
        string memory tokenURI_2_initial = targetPressProxy.tokenURI(2);

        // structure new data to overwrite tokens with
        CurationDatabaseV1.Listing[] memory newTokenData = new CurationDatabaseV1.Listing[](2);
        newTokenData[0].chainId = 4;
        newTokenData[0].tokenId = 7;
        newTokenData[0].listingAddress = address(0x6501);
        newTokenData[0].hasTokenId = 1;
        newTokenData[1].chainId = 666;
        newTokenData[1].tokenId = 0;
        newTokenData[1].listingAddress = address(0x82d4);
        newTokenData[1].hasTokenId = 0;
        bytes memory newEncodedListing_1 = abi.encode(
            newTokenData[0].chainId, newTokenData[0].tokenId, newTokenData[0].listingAddress, newTokenData[0].hasTokenId
        );
        bytes memory newEncodedListing_2 = abi.encode(
            newTokenData[1].chainId, newTokenData[1].tokenId, newTokenData[1].listingAddress, newTokenData[1].hasTokenId
        );
        // overwrite() takes in calldata arrays but you can pass in memory arrays as they are treated as calldata if specified in the function
        bytes[] memory overwriteDataArray = new bytes[](2);
        overwriteDataArray[0] = newEncodedListing_1;
        overwriteDataArray[1] = newEncodedListing_2;
        uint256[] memory tokenIdArray = new uint256[](2);
        tokenIdArray[0] = 1;
        tokenIdArray[1] = 2;
        targetPressProxy.overwrite(tokenIdArray, overwriteDataArray);
        (bytes[] memory newDatabaseReturn) = database.readAllData(address(targetPressProxy));
        require(
            keccak256(bytes(targetPressProxy.tokenURI(1))) != keccak256(bytes(tokenURI_1_initial)),
            "tokenURI #1 should be different after data overwrite"
        );
        require(
            keccak256(bytes(targetPressProxy.tokenURI(2))) != keccak256(bytes(tokenURI_2_initial)),
            "tokenURI #1 should be different after data overwrite"
        );
    }

    function test_burn() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](3);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        listings[1].chainId = 7777777;
        listings[1].tokenId = 0;
        listings[1].listingAddress = address(0x54321);
        listings[1].hasTokenId = 0;
        listings[2].chainId = 100;
        listings[2].tokenId = 2;
        listings[2].listingAddress = address(0xbd720);
        listings[2].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(3, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 3, "mint not functioning correctly");
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        require(targetPressProxy.ownerOf(2) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        require(targetPressProxy.ownerOf(3) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        require(targetPressProxy.exists(1) == true, "incorrect exists return");
        require(targetPressProxy.exists(2) == true, "incorrect exists return");
        require(targetPressProxy.exists(3) == true, "incorrect exists return");

        targetPressProxy.burn(1);
        // ownerOf should revert if token does not exist anymore post burn
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(1);
        require(targetPressProxy.exists(1) == false, "exists should be false after burn");

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 2;
        tokenIds[1] = 3;
        targetPressProxy.burnBatch(tokenIds);
        // ownerOf should revert if token does not exist anymore post burn
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(2);
        vm.expectRevert(abi.encodeWithSignature("OwnerQueryForNonexistentToken()"));
        targetPressProxy.ownerOf(3);
        require(targetPressProxy.exists(3) == false, "exists should be false after burn");
        require(targetPressProxy.exists(3) == false, "exists should be false after burn");
    }

    function test_updateSettings() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");
        targetPressProxy.updateSettings(payable(address(0x12345)), 300);
        (IERC721Press.Settings memory newSettings) = targetPressProxy.getSettings();
        require(newSettings.fundsRecipient == payable(address(0x12345)), "funds recipient set incorrectly");
        require(newSettings.royaltyBPS == 300, "funds recipient set incorrectly");
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER does not have access to updateSettings function
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        targetPressProxy.updateSettings(payable(address(0x12345)), 300);
    }

    function test_royaltyInfo() public setUpCurationStrategy {
        uint256 priceInWei = 100000000000000000; // 0.1 eth
        uint256 precalculatedRoyalty = priceInWei * 250 / 10_000; // 0.1 eth * 2.5% royalty = 0.0025 eth aka 2500000000000000 wei
        (address receiver, uint256 expectedRoyaltyValue) = targetPressProxy.royaltyInfo(1, priceInWei);
        require(precalculatedRoyalty == expectedRoyaltyValue, "royalties not calculated correctly");
    }

    function test_paymentRouting() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // set up mock logic for tests
        MockLogic mockLogic = new MockLogic();
        bytes memory mockLogicInit = "0x12345";
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);
        vm.stopPrank();

        // mockLogic mint price check + fetch
        mockLogic.getMintPrice(address(0x123), address(0x123), 1);
        uint256 totalMintPrice = CurationDatabaseV1(address(targetPressProxy.getDatabase())).totalMintPrice(
            address(targetPressProxy), msg.sender, 1
        );

        // get funds recipient + deal funds to minter
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        vm.deal(PRESS_USER, 1 ether);

        vm.startPrank(PRESS_USER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData{value: totalMintPrice}(1, encodedListings);
        require(PRESS_USER.balance == (1 ether - totalMintPrice), "incorrect eth balance of minter");
        require(pressSettings.fundsRecipient.balance == totalMintPrice, "incorrect eth balance of funds recipient");
    }

    function test_nonTransferableTokens() public setUpCurationStrategy {
        // confirm token transferability set to false
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == false, "token transferability set incorrectly");

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should revert because Press is set to have non transferable tokens
        vm.expectRevert(abi.encodeWithSignature("Non_Transferrable_Token()"));
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, address(0x123), 1, new bytes(0));
    }

    function test_transferableTokens() public setUpCurationStrategy_TransferableTokens {
        // confirm token transferability set to true
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == true, "token transferability set incorrectly");

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should NOT revert because Press is set to have transferable tokens
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, PRESS_USER, 1, new bytes(0));
        require(targetPressProxy.ownerOf(1) == PRESS_USER, "incorrect tokenOwner");
    }

    function test_transferPressOwnership() public setUpCurationStrategy {
        vm.startPrank(PRESS_USER);
        // expect revert on transfer because msg.sender is not owner
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        targetPressProxy.transferOwnership(PRESS_USER);
        vm.stopPrank();
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // transfer should go through since being called from contract owner
        targetPressProxy.transferOwnership(PRESS_USER);
        require(targetPressProxy.owner() == PRESS_USER, "ownership not transferred correctly");
    }

    // TODO: add in a test upgrading Press Proxy to a new implementation
    // *
    // *
    // *
    // *
    // *
}
