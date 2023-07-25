// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "../utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV1} from "../../../src/strategies/curation/database/CurationDatabaseV1.sol";
import {IERC5192} from "../../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from
    "../../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";

import {MockERC721} from "../utils/mocks/MockERC721.sol";
import {MockRenderer} from "../utils/mocks/MockRenderer.sol";
import {MockLogic} from "../utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {
    IERC2981Upgradeable,
    IERC165Upgradeable
} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract CurationDatabaseV1Test is ERC721PressConfig {
    function test_initialize() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on initialization
        (uint256 storedCounter, address pressLogic, uint8 initialized, address pressRenderer) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        require(storedCounter == 0, "stored counter should be zero since no mints have occurred");
        require(pressLogic == address(logic), "press logic initialized in database incorrectly");
        require(initialized == 1, "initialized should equal 1 post initialization");
        require(pressRenderer == address(renderer), "press renderer initialized in database incorrectly");
    }

    function test_storeAndRead() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on initialization
        (uint256 storedCounter, address pressLogic, uint8 initialized, address pressRenderer) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);

        // invalid data tests
        bytes[] memory testDataArray = new bytes[](1);
        testDataArray[0] = abi.encode("this is just a test");
        bytes memory encodedArray = abi.encode(testDataArray);
        // this should revert because trying to store invalid data for CurationDatabaseV1
        vm.expectRevert();
        targetPressProxy.mintWithData(1, encodedArray);

        // valid data tesets
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
        // array of structs that look like {bytes storedData, int96 sortOrder}
        bytes[] memory tokenData = database.readAllData(address(targetPressProxy));
        require(
            keccak256(tokenData[0])
                == keccak256(
                    abi.encode(listings[0].chainId, listings[0].tokenId, listings[0].listingAddress, listings[0].hasTokenId)
                ),
            "token #1 data not stored properly"
        );
        require(
            keccak256(tokenData[1])
                == keccak256(
                    abi.encode(listings[1].chainId, listings[1].tokenId, listings[1].listingAddress, listings[1].hasTokenId)
                ),
            "token #2 data not stored properly"
        );

        // process PRESS_USER mints for later checks
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        targetPressProxy.mintWithData(2, encodedListings);
        targetPressProxy.mintWithData(2, encodedListings);
        vm.stopPrank();

        // check access for expected scenarios for this initialization strategy
        // PRESS_ADMIN_AND_OWNER
        require(
            database.canMint(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 3) == true,
            "admin minter caller should have different access"
        );
        require(
            database.canBurn(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 1) == true,
            "admin burn caller should have different access"
        );
        require(
            database.canSort(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true,
            "admin sort caller should have different access"
        );
        require(
            database.canEditSettings(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true,
            "admin settings caller should have different access"
        );
        require(
            database.canEditContractData(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true,
            "admin contract data caller should have different access"
        );
        require(
            database.canEditTokenData(address(targetPressProxy), PRESS_ADMIN_AND_OWNER, 1) == false,
            "admin token data caller should have different access"
        );
        require(
            database.canEditPayments(address(targetPressProxy), PRESS_ADMIN_AND_OWNER) == true,
            "admin payments caller should have different access"
        );
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // burn should process since PRESS_ADMIN_AND_OWNER is owner of token being burned
        targetPressProxy.burn(1);
        // burn should process since PRESS_ADMIN_AND_OWNER is NOT owner of token being burned but DOES have override access
        targetPressProxy.burn(3);
        vm.stopPrank();

        // PRESS_MANAGER (manager has admin esque burn access)
        require(
            database.canMint(address(targetPressProxy), PRESS_MANAGER, 3) == true,
            "manager mint caller should have different access"
        );
        require(
            database.canBurn(address(targetPressProxy), PRESS_MANAGER, 1) == true,
            "manager burn caller should have different access"
        );
        require(
            database.canSort(address(targetPressProxy), PRESS_MANAGER) == true,
            "manager sort caller should have different access"
        );
        require(
            database.canEditSettings(address(targetPressProxy), PRESS_MANAGER) == false,
            "manager settings caller should have different access"
        );
        require(
            database.canEditContractData(address(targetPressProxy), PRESS_MANAGER) == true,
            "manager contract data caller should have different access"
        );
        require(
            database.canEditTokenData(address(targetPressProxy), PRESS_MANAGER, 1) == false,
            "manager token data caller should have different access"
        );
        require(
            database.canEditPayments(address(targetPressProxy), PRESS_MANAGER) == false,
            "manager payments caller should have different access"
        );
        vm.startPrank(PRESS_MANAGER);
        targetPressProxy.mintWithData(2, encodedListings);
        // burn should process since PRESS_MANAGER is owner of token being burned
        targetPressProxy.burn(7);
        // burn should process since PRESS_MANAGER is NOT owner of token being burned but DOES have override access
        targetPressProxy.burn(5);
        vm.stopPrank();

        // PRESS_USER
        require(
            database.canMint(address(targetPressProxy), PRESS_USER, 3) == true,
            "user mint caller should have different access"
        );
        require(
            database.canBurn(address(targetPressProxy), PRESS_USER, 1) == false,
            "user burn caller should have different access"
        );
        require(
            database.canSort(address(targetPressProxy), PRESS_USER) == false,
            "user sort caller should have different access"
        );
        require(
            database.canEditSettings(address(targetPressProxy), PRESS_USER) == false,
            "user settings caller should have different access"
        );
        require(
            database.canEditContractData(address(targetPressProxy), PRESS_USER) == false,
            "user contract data caller should have different access"
        );
        require(
            database.canEditTokenData(address(targetPressProxy), PRESS_USER, 1) == false,
            "user token data caller should have different access"
        );
        require(
            database.canEditPayments(address(targetPressProxy), PRESS_USER) == false,
            "user payments caller should have different access"
        );
        vm.startPrank(PRESS_USER);
        targetPressProxy.mintWithData(2, encodedListings);
        // burn should process since PRESS_USER is owner of token being burned
        targetPressProxy.burn(6);
        vm.expectRevert(abi.encodeWithSignature("No_Burn_Access()"));
        // burn should revert since PRESS_USER is NOT owner of token being burned and doesnt have override access
        targetPressProxy.burn(2);
        vm.stopPrank();

        // PRESS_NO_ROLE
        require(
            database.canMint(address(targetPressProxy), PRESS_NO_ROLE_1, 3) == false,
            "non-user mint caller should have different access"
        );
        require(
            database.canBurn(address(targetPressProxy), PRESS_NO_ROLE_1, 1) == false,
            "non-user burn caller should have different access"
        );
        require(
            database.canSort(address(targetPressProxy), PRESS_NO_ROLE_1) == false,
            "non-user sort caller should have different access"
        );
        require(
            database.canEditSettings(address(targetPressProxy), PRESS_NO_ROLE_1) == false,
            "non-user settings caller should have different access"
        );
        require(
            database.canEditContractData(address(targetPressProxy), PRESS_NO_ROLE_1) == false,
            "non-user contract data caller should have different access"
        );
        require(
            database.canEditTokenData(address(targetPressProxy), PRESS_NO_ROLE_1, 1) == false,
            "non-user token data caller should have different access"
        );
        require(
            database.canEditPayments(address(targetPressProxy), PRESS_NO_ROLE_1) == false,
            "non-user payments caller should have different access"
        );

        // readAllData return should be an array of length 5 since 10 tokens have been minted by this point and 5 tokens have been burned
        bytes[] memory tokenDataPostBurn = database.readAllData(address(targetPressProxy));
        bytes memory bytesZeroValue = new bytes(0);
        require(
            keccak256(tokenDataPostBurn[0]) == keccak256(bytesZeroValue),
            "token 1 data not removed corectly during burn"
        );
        require(
            keccak256(tokenDataPostBurn[2]) == keccak256(bytesZeroValue),
            "token 3 data not removed corectly during burn"
        );
        require(
            keccak256(tokenDataPostBurn[4]) == keccak256(bytesZeroValue),
            "token 5 data not removed corectly during burn"
        );
        require(
            keccak256(tokenDataPostBurn[5]) == keccak256(bytesZeroValue),
            "token 6 data not removed corectly during burn"
        );
        require(
            keccak256(tokenDataPostBurn[6]) == keccak256(bytesZeroValue),
            "token 7 data not removed corectly during burn"
        );

        // require(tokenDataPostBurn.length == 5, "read data not skipping burned tokens");
    }

    function test_sortAndRead() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);

        // mint tokens to sort
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
        vm.stopPrank();

        // setup + call sort

        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;

        int128[] memory sortOrders = new int128[](2);
        sortOrders[0] = 1;
        sortOrders[1] = -1;

        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER does not have sort access
        vm.expectRevert(abi.encodeWithSignature("No_Sort_Access()"));
        database.sortData(address(targetPressProxy), tokenIds, sortOrders);

        vm.stopPrank();
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        database.sortData(address(targetPressProxy), tokenIds, sortOrders);

        // checks that sortOrders being stored in database `idToData` mapping correctly
        int128 sortValue = database.slotToSort(address(targetPressProxy), 0);
        require(sortOrders[0] == sortValue, "sort order incorrect");
        int128 sortValue_2 = database.slotToSort(address(targetPressProxy), 1);
        require(sortOrders[1] == sortValue_2, "sort order incorrect");

        // checks that sortOrders generated correctly in readAllData call as well
        int128[] memory sortData = database.getAllSortData(address(targetPressProxy));
        require(sortData[0] == sortOrders[0], "sort order should be 1 here");
        require(sortData[1] == sortOrders[1], "sort order should be -1 here");
    }

    function test_overwriteAndRead() public setUpCurationStrategy_MutableMetadata {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on mint calls
        vm.startPrank(PRESS_ADMIN_AND_OWNER);

        // Incorrect data storage
        bytes[] memory testDataArray = new bytes[](1);
        testDataArray[0] = abi.encode("this is just a test");
        bytes memory encodedArray = abi.encode(testDataArray);
        // this should revert because trying to store invalid data for CurationDatabaseV1
        vm.expectRevert();
        targetPressProxy.mintWithData(1, encodedArray);

        // Correct Data storage
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

        bytes[] memory initialDatabaseReturn = database.readAllData(address(targetPressProxy));

        require(
            keccak256(initialDatabaseReturn[0])
                == keccak256(
                    abi.encode(
                        initialTokenData[0].chainId,
                        initialTokenData[0].tokenId,
                        initialTokenData[0].listingAddress,
                        initialTokenData[0].hasTokenId
                    )
                ),
            "token #1 data stored incorrectly"
        );
        require(
            keccak256(initialDatabaseReturn[1])
                == keccak256(
                    abi.encode(
                        initialTokenData[1].chainId,
                        initialTokenData[1].tokenId,
                        initialTokenData[1].listingAddress,
                        initialTokenData[1].hasTokenId
                    )
                ),
            "token #2 data stored incorrectly"
        );

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
        bytes[] memory newDatabaseReturn = database.readAllData(address(targetPressProxy));
        require(
            keccak256(newDatabaseReturn[0]) == keccak256(overwriteDataArray[0]), "token #1 data overwritten incorrectly"
        );
        require(
            keccak256(newDatabaseReturn[1]) == keccak256(overwriteDataArray[1]), "token #2 data overwrriten incorrectly"
        );
    }

    function test_setRenderer() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on initialization
        (uint256 storedCounter, address pressLogic, uint8 initialized, address pressRenderer) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        // set up mock renderer for tests
        MockRenderer mockRenderer = new MockRenderer();
        bytes memory mockRendererInit = "0x12345";

        // check for correct reverts for calling setLogic without access
        vm.startPrank(PRESS_MANAGER);
        // should revert because PRESS_MANAGER does not have access to update database settings for given Press
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        database.setRenderer(address(targetPressProxy), address(mockRenderer), mockRendererInit);
        vm.stopPrank();

        // check for successfull calls for calling setRenderer with access
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        database.setRenderer(address(targetPressProxy), address(mockRenderer), mockRendererInit);

        // check database storage on initialization
        (uint256 storedCounter_2, address pressLogic_2, uint8 initialized_2, address pressRenderer_2) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        // check that address of renderer was updated correctly + renderer was initialized correctly
        require(pressRenderer_2 == address(mockRenderer), "press renderer updated in database incorrectly");
        require(
            mockRenderer.pressInitializedInfo(address(targetPressProxy)) == true,
            "mock renderer not initialized properly"
        );
    }

    function test_setLogic() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // check database storage on initialization
        (uint256 storedCounter, address pressLogic, uint8 initialized, address pressRenderer) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        // set up mock logic for tests
        MockLogic mockLogic = new MockLogic();
        bytes memory mockLogicInit = "0x12345";

        // check for correct reverts for calling setLogic without access
        vm.startPrank(PRESS_MANAGER);
        // should revert because PRESS_MANAGER does not have access to update database settings for given Press
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);
        vm.stopPrank();

        // check for successfull calls for calling setLogic with access
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);

        // check database storage on initialization
        (uint256 storedCounter_2, address pressLogic_2, uint8 initialized_2, address pressRenderer_2) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).settingsInfo(address(targetPressProxy));

        // check that address of logic was updated correctly + logic was initialized correctly
        require(pressLogic_2 == address(mockLogic), "press logic updated in database incorrectly");
        require(
            mockLogic.pressInitializedInfo(address(targetPressProxy)) == true, "mock logic not initialized properly"
        );
    }

    function test_isInitialized() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        (bool isInitialized) =
            CurationDatabaseV1(address(targetPressProxy.getDatabase())).isInitialized(address(targetPressProxy));

        require(isInitialized == true, "isInitialized() not working correctly");
    }

    function test_totalMintPrice() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        (uint256 totalMintPrice) = CurationDatabaseV1(address(targetPressProxy.getDatabase())).totalMintPrice(
            address(targetPressProxy),
            address(0x123), // mock msg.sender
            1000 // mock quantity
        );

        require(totalMintPrice == 0, "totalMintPrice() not working correctly");
    }

    function test_contractURI() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        vm.startPrank(address(targetPressProxy));
        (string memory contractURI) = CurationDatabaseV1(address(targetPressProxy.getDatabase())).contractURI();

        require(
            keccak256(bytes(contractURI))
                == keccak256(
                    bytes(
                        "data:application/json;base64,eyJuYW1lIjogIlB1YmxpYyBBc3NlbWJseSIsImRlc2NyaXB0aW9uIjogIlRoaXMgY2hhbm5lbCBpcyBvd25lZCBieSAweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAzMzNcblxuVGhlIHRva2VucyBpbiB0aGlzIGNvbGxlY3Rpb24gcHJvdmlkZSBwcm9vZi1vZi1jdXJhdGlvbiBhbmQgYXJlIG5vbi10cmFuc2ZlcmFibGUuXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImlwZnM6Ly9USElTX0NPVUxEX0JFX0NPTlRSQUNUX1VSSV9JTUFHRV9QQVRIIn0="
                    )
                ),
            "contractURI not working correctly"
        );
        vm.stopPrank();

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1 testDatabase = CurationDatabaseV1(address(targetPressProxy.getDatabase()));
        // expect revert because contractURI call coming from an address besides the PRESS that was initialized
        vm.expectRevert(abi.encodeWithSignature("Press_Not_Initialized()"));
        testDatabase.contractURI();
    }

    function test_tokenURI() public setUpCurationStrategy {
        require(address(targetPressProxy.getDatabase()) == address(database), "database address incorrect");

        // build data for tokens
        CurationDatabaseV1.Listing[] memory listings = new CurationDatabaseV1.Listing[](1);
        listings[0].chainId = 1;
        listings[0].tokenId = 3;
        listings[0].listingAddress = address(0x12345);
        listings[0].hasTokenId = 1;
        bytes memory encodedListings = encodeListingArray(listings);
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        targetPressProxy.mintWithData(1, encodedListings);
        vm.stopPrank();

        vm.startPrank(address(targetPressProxy));

        (string memory tokenURI) = CurationDatabaseV1(address(targetPressProxy.getDatabase())).tokenURI(1);

        // {"name": "Curation Receipt #1","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000333\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"chainId": "1","contract": "0x0000000000000000000000000000000000012345","hasTokenId": "1","tokenId": "3","sortOrder": "0","curator": "0x0000000000000000000000000000000000000333"}}
        require(
            keccak256(bytes(tokenURI))
                == keccak256(
                    bytes(
                        "data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzEiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMzMzXG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY2hhaW5JZCI6ICIxIiwiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDEyMzQ1IiwiaGFzVG9rZW5JZCI6ICIxIiwidG9rZW5JZCI6ICIzIiwic29ydE9yZGVyIjogIjAiLCJjdXJhdG9yIjogIjB4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDMzMyJ9fQ=="
                    )
                ),
            "tokenURI not working correctly"
        );
        vm.stopPrank();

        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        CurationDatabaseV1 testDatabase = CurationDatabaseV1(address(targetPressProxy.getDatabase()));
        // expect revert because tokenURI call coming from an address besides the PRESS that was initialized
        vm.expectRevert(abi.encodeWithSignature("Press_Not_Initialized()"));
        testDatabase.tokenURI(1);
    }
}
