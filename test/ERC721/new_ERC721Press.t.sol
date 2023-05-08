// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";
import {New_ERC721PressConfig} from "./utils/new_ERC721PressConfig.sol";

import {IERC721PressFactory} from "../../src/token/ERC721/core/interfaces/IERC721PressFactory.sol";
import {IERC721Press} from "../../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {ERC721PressFactoryProxy} from "../../src/token/ERC721/core/proxy/ERC721PressFactoryProxy.sol";
import {ERC721PressFactory} from "../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721Press} from "../../src/token/ERC721/ERC721Press.sol";

import {HybridAccess} from "../../src/token/ERC721/strategies//curation/access/HybridAccess.sol";
import {OpenAccess} from "../../src/token/ERC721/strategies//curation/access/OpenAccess.sol";
import {ICurationLogic} from "../../src/token/ERC721/strategies//curation/interfaces/ICurationLogic.sol";
import {New_CurationLogic} from "../../src/token/ERC721/strategies//curation/logic/New_CurationLogic.sol";
import {IERC5192} from "../../src/token/ERC721/core/interfaces/IERC5192.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract New_ERC721PressTest is New_ERC721PressConfig {

    function encodeListing(ICurationLogic.Listing memory _listing) public pure returns (bytes memory) {
        return abi.encode(
            _listing.curatedAddress,
            _listing.selectedTokenId,
            _listing.curator,
            _listing.sortOrder,
            _listing.chainId,
            _listing.curationTargetType,
            _listing.hasTokenId
        );
    }

    event encodedListingBytes (bytes theBytes, uint256 lengthBytes);

    function encodeListingArray(ICurationLogic.Listing[] memory _listings) public returns (bytes memory) {
        bytes memory encodedListings;
        for (uint i = 0; i < _listings.length; i++) {
            encodedListings = abi.encodePacked(encodedListings, encodeListing(_listings[i]));
            emit encodedListingBytes(encodeListing(_listings[i]), encodeListing(_listings[i]).length);
        }
        return encodedListings;
    }

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_newMintWithData() public setUpPressCurationLogic {      
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();    
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        // listings[1].curatedAddress = address(0x333);
        // listings[1].selectedTokenId = 0;
        // listings[1].curator = CURATOR_1;
        // listings[1].curationTargetType = 1; // curationType = NFT Contract
        // listings[1].sortOrder = -1;
        // listings[1].hasTokenId = false;
        // listings[1].chainId = 1;        

        bytes memory encodedListings = encodeListingArray(listings);
        // bytes memory encodedListings = abi.encode(listings);

        erc721Press.mintWithData(1, encodedListings);

        ( 
            address curatedAddress,
            uint96 selectedTokenId,
            address curator,
            int32 sortOrder,
            uint16 chainId,
            uint16 curationTargetType,
            bool hasTokenId
        ) = curationLogic.getTheListing(address(erc721Press), 0);

        require(curatedAddress == listings[0].curatedAddress, "curatedaddress manipulation incorrect");
        require(selectedTokenId == listings[0].selectedTokenId, "selectedTokenId manipulation incorrect");
        require(curator == listings[0].curator, "curator manipulation incorrect");
        require(sortOrder == listings[0].sortOrder, "sortOrder manipulation incorrect");
        require(chainId == listings[0].chainId, "chainId manipulation incorrect");
        require(curationTargetType == listings[0].curationTargetType, "curationTargetType manipulation incorrect");
        require(hasTokenId == listings[0].hasTokenId, "hasTokenId manipulation incorrect");
    }
}