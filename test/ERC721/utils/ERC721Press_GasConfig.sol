// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC721Press} from "../../../src/token/ERC721/ERC721Press.sol";
import {ERC721PressProxy} from "../../../src/token/ERC721/core/proxy/ERC721PressProxy.sol";
import {IERC721Press} from "../../../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {ERC721PressFactory} from "../../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721PressFactoryProxy} from "../../../src/token/ERC721/core/proxy/ERC721PressFactoryProxy.sol";
import {ICurationLogic} from "../../../src/token/ERC721/strategies/curation/interfaces/ICurationLogic.sol";
import {CurationLogic} from "../../../src/token/ERC721/strategies/curation/logic/CurationLogic.sol";

import {CurationMetadataRenderer} from "../../../src/token/ERC721/strategies/curation/metadata/CurationMetadataRenderer.sol";
import {OpenAccess} from "../../../src/token/ERC721/strategies/access/OpenAccess.sol";

contract ERC721Press_GasConfig is Test {
    address public constant INITIAL_OWNER = address(0x01);
    address public constant FUNDS_RECIPIENT = address(0x02);   
    uint64 maxSupply = type(uint64).max;
    ERC721Press erc721Press;
    address public erc721PressImpl;

    /* CURATION STUFF HERE */
    bool initialPauseState = false;
    // Deploy the CurationLogic contract
    CurationLogic public curationLogic = new CurationLogic();
    // Deploy the CurationMetadataRenderer contract
    CurationMetadataRenderer public curationRenderer = new CurationMetadataRenderer();
    // Deploy the OpenAccess contract
    OpenAccess public openAccess = new OpenAccess();
    // set up curation logic init
    bytes curLogicInit = abi.encode(initialPauseState, openAccess, "");

    // Set up called before each test
    function setUp() public {
        // Deploy an ERC721Press instance
        erc721PressImpl = address(new ERC721Press());

        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC721PressProxy(erc721PressImpl, "")));

        erc721Press = ERC721Press(pressProxy);

        // set up configuration
        IERC721Press.Configuration memory configuration = IERC721Press.Configuration({
            fundsRecipient: payable(FUNDS_RECIPIENT),
            maxSupply: maxSupply,
            royaltyBPS: 1000,
            primarySaleFeeRecipient: payable(FUNDS_RECIPIENT),
            primarySaleFeeBPS: 1000
        });

         // Initialize the proxy
        erc721Press.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _logic: curationLogic,
            _logicInit: curLogicInit,
            _renderer: curationRenderer,
            _rendererInit: "",
            _soulbound: true,            
            _configuration: configuration                        
        });              
    }

    // TEST SUITE ENCODING HELPERS 

    event encodedListingBytes (bytes theBytes, uint256 lengthBytes);

    function encodeListing(ICurationLogic.Listing memory _listing) public pure returns (bytes memory) {
        return abi.encode(
            _listing.chainId,
            _listing.tokenId,
            _listing.listingAddress,
            _listing.sortOrder,
            _listing.hasTokenId
        );
    }    

    function encodeListingArray(ICurationLogic.Listing[] memory _listings) public returns (bytes memory) {
        bytes[] memory encodedListings = new bytes[](_listings.length);
        for (uint i = 0; i < _listings.length; i++) {
            encodedListings[i] = encodeListing(_listings[i]);
        }
        return abi.encode(encodedListings);
    }                  
}
