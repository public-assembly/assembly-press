// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/setup/ERC721PressConfig.sol";

import {IERC721Press} from "../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721PressDatabaseV1} from "../../src/core/token/ERC721/database/ERC721PressDatabaseV1.sol";
import {IERC5192} from "../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationMetadataRenderer} from "../../src/strategies/curation/renderer/CurationMetadataRenderer.sol";
import {MockLogic} from "./utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

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

    function test_mintWithData() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        PartialListing[] memory listings = new PartialListing[](2);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        listings[1].chainId = 7777777;       
        listings[1].tokenId = 0;              
        listings[1].listingAddress = address(0x54321);               
        listings[1].hasTokenId = false;    
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(2, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 2, "mint not functioning correctly");         
    } 

    function test_burn() public setUpCurationStrategy() {
        // burn 

        // burn batch
    }

    function test_sort() public setUpCurationStrategy() {

    }
            

    function test_setSettings() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.fundsRecipient == PRESS_FUNDS_RECIPIENT, "funds recipient set incorrectly");
        require(pressSettings.royaltyBPS == 250, "funds recipient set incorrectly");        
        targetPressProxy.setSettings(payable(address(0x12345)), 300);   
        (IERC721Press.Settings memory newSettings) = targetPressProxy.getSettings();
        require(newSettings.fundsRecipient == payable(address(0x12345)), "funds recipient set incorrectly");
        require(newSettings.royaltyBPS == 300, "funds recipient set incorrectly");           
        vm.stopPrank();
        vm.startPrank(PRESS_USER);
        // should revert because PRESS_USER does not have access to setSettings function
        vm.expectRevert(abi.encodeWithSignature("No_Settings_Access()"));
        targetPressProxy.setSettings(payable(address(0x12345)), 300);   
    }     

    function test_royaltyInfo() public setUpCurationStrategy {
        uint256 priceInWei = 100000000000000000; // 0.1 eth
        uint256 precalculatedRoyalty = priceInWei * 250 / 10_000; // 0.1 eth * 2.5% royalty = 0.0025 eth aka 2500000000000000 wei
        (address receiver, uint256 expectedRoyaltyValue) = targetPressProxy.royaltyInfo(1, priceInWei);
        require(precalculatedRoyalty == expectedRoyaltyValue, "royalties not calculated correctly");
    }         

    function test_mintWithData_paymentRouting() public setUpCurationStrategy {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);
        // set up mock logic for tests
        MockLogic mockLogic = new MockLogic();
        bytes memory mockLogicInit = "0x12345";
        database.setLogic(address(targetPressProxy), address(mockLogic), mockLogicInit);
        vm.stopPrank();

        // mockLogic mint price check + fetch
        mockLogic.getMintPrice(address(0x123), address(0x123), 1);
        uint256 totalMintPrice = ERC721PressDatabaseV1(address(targetPressProxy.getDatabase())).totalMintPrice(
            address(targetPressProxy), 
            msg.sender, 
            1
        );        

        // get funds recipient + deal funds to minter
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();        
        vm.deal(PRESS_USER, 1 ether);

        vm.startPrank(PRESS_USER);
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData{
            value: totalMintPrice
        }(1, encodedListings);
        require(
            PRESS_USER.balance == (1 ether - totalMintPrice), "incorrect eth balance of minter"
        );
        require(
            pressSettings.fundsRecipient.balance == totalMintPrice, "incorrect eth balance of funds recipient"
        );        
    }

    function test_nonTransferableTokens() public setUpCurationStrategy {
        
        // confirm token transferability set to false
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == false, "token transferability set incorrectly");        
        
        vm.startPrank(PRESS_ADMIN_AND_OWNER);         
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should revert because Press is set to have non transferable tokens
        vm.expectRevert(abi.encodeWithSignature("Non_Transferrable_Token()"));
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, address(0x123), 1, new bytes(0));        
    }         

    function test_transferableTokens() public setUpCurationStrategy_TransferableTokens() {
        
        // confirm token transferability set to true
        (IERC721Press.Settings memory pressSettings) = targetPressProxy.getSettings();
        require(pressSettings.transferable == true, "token transferability set incorrectly");        
        
        vm.startPrank(PRESS_ADMIN_AND_OWNER);         
        PartialListing[] memory listings = new PartialListing[](1);
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = true;       
        bytes memory encodedListings = encodeListingArray(listings);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.ownerOf(1) == PRESS_ADMIN_AND_OWNER, "incorrect tokenOwner");
        // token transfer should NOT revert because Press is set to have transferable tokens
        targetPressProxy.safeTransferFrom(PRESS_ADMIN_AND_OWNER, PRESS_USER, 1, new bytes(0));        
        require(targetPressProxy.ownerOf(1) == PRESS_USER, "incorrect tokenOwner");
    }             

    /* TODO
    * 1. add burn tests
    * 2. add sort tests
    * 3. add mintBurnSort tests
    * 4. add tests for upgrades + transfers
    * 5. do factory impl + tests
    * 6. deploys ???
    * 7. first pass diagrams
    */      
}