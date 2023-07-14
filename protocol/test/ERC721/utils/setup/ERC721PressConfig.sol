// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {IERC721Press} from "../../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {ERC721Press} from "../../../../src/core/token/ERC721/ERC721Press.sol";
import {ERC721PressProxy} from "../../../../src/core/token/ERC721/proxy/ERC721PressProxy.sol";
import {CurationDatabaseV1} from "../../../../src/strategies/curation/database/CurationDatabaseV1.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationRendererV1} from "../../../../src/strategies/curation/renderer/CurationRendererV1.sol";
import {TokenGateFeeModule} from "../../../../src/strategies/curation/fees/TokenGateFeeModule.sol";

import {MockERC721} from "../mocks/MockERC721.sol";
import {MockDatabase} from "../mocks/MockDatabase.sol";

contract ERC721PressConfig is Test {

    // ADDRESSES FOR DATABASE OWNERSHIP + OFFICIAL FACTORY
    address public primaryOwner;
    address public secondaryOwner;
    address public mockFactory;
    // ADDRESSES FOR PRESS + PRESS PROXY
    ERC721Press public erc721PressImpl;
    ERC721Press public targetPressProxy;
    // HELPFUL CONSTANTS
    uint256 public constant maxSupply = type(uint256).max;
    // ACTORS + ROLES + ACCESS PASS
    address public constant PRESS_ADMIN_AND_OWNER = address(0x333);
    address public constant PRESS_MANAGER = address(0x222);
    address public constant PRESS_USER = address(0x111);
    address public constant PRESS_NO_ROLE_1 = address(0x001);
    address public constant PRESS_NO_ROLE_2 = address(0x002);
    address payable public constant PRESS_FUNDS_RECIPIENT = payable(address(0x999));
    uint8 public constant ADMIN_ROLE = 3;
    uint8 public constant MANAGER_ROLE = 2;
    uint8 public constant USER = 1;
    uint8 public constant NO_ROLE = 0;        
    MockERC721 public mockAccessPass = new MockERC721();
    // DATABASE + LOGIC + RENDERER SETUP
    CurationDatabaseV1 internal database = new CurationDatabaseV1(primaryOwner, secondaryOwner);
    MockDatabase public mockDatabase = new MockDatabase(primaryOwner, secondaryOwner);
    RolesWith721GateImmutableMetadataNoFees public logic = new RolesWith721GateImmutableMetadataNoFees();
    CurationRendererV1 public renderer = new CurationRendererV1();
    TokenGateFeeModule public feeModule = new TokenGateFeeModule(address(0), 0, address(0));

    // Gets run before every test 
    function setUp() public {
        // DEPLOY PRESS + PRESS PROXY CONTRACTS
        erc721PressImpl = new ERC721Press();        
        targetPressProxy = ERC721Press(payable(address(new ERC721PressProxy(address(erc721PressImpl), ""))));  
        // Artificially initialize Press Proxy address in the database
        vm.startPrank(primaryOwner);
        database.setOfficialFactory(mockFactory);
        vm.stopPrank();
        vm.startPrank(mockFactory);
        database.initializePress(address(targetPressProxy), address(feeModule));
        vm.stopPrank();
    }

    modifier setUpCurationStrategy() {

        // SETUP LOGIC INIT
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory initialRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](2);
        initialRoles[0].account = PRESS_ADMIN_AND_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = PRESS_MANAGER;
        initialRoles[1].role = MANAGER_ROLE;      
        mockAccessPass.mint(PRESS_USER);   
        bool initialIsPaused = false;     
        bool initialIsTokenDataImmutable = true;
        bytes memory logicInit = abi.encode(address(mockAccessPass), initialIsPaused, initialIsTokenDataImmutable, initialRoles);

        // SETUP RENDERER INIT
        string memory contractUriImagePath = "ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH";
        bytes memory rendererInit = abi.encode(contractUriImagePath);

        // SETUP DATABASE INIT
        bytes memory databaseInit = abi.encode(
            address(logic),
            logicInit,
            address(renderer),
            rendererInit
        );

        // PRESS SETTINGS
        IERC721Press.Settings memory pressSettings = IERC721Press.Settings({
            fundsRecipient: PRESS_FUNDS_RECIPIENT,
            royaltyBPS: 250, // 2.5%
            transferable: false
        });

         // INITIALIZE PROXY
        targetPressProxy.initialize({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            database: database,
            databaseInit: databaseInit,
            settings: pressSettings                    
        });        

        _;
    }

    modifier setUpCurationStrategy_MutableMetadata() {

        // SETUP LOGIC INIT
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory initialRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](2);
        initialRoles[0].account = PRESS_ADMIN_AND_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = PRESS_MANAGER;
        initialRoles[1].role = MANAGER_ROLE;      
        mockAccessPass.mint(PRESS_USER);   
        bool initialIsPaused = false;     
        bool initialIsTokenDataImmutable = false;
        bytes memory logicInit = abi.encode(address(mockAccessPass), initialIsPaused, initialIsTokenDataImmutable, initialRoles);

        // SETUP RENDERER INIT
        string memory contractUriImagePath = "ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH";
        bytes memory rendererInit = abi.encode(contractUriImagePath);

        // SETUP DATABASE INIT
        bytes memory databaseInit = abi.encode(
            address(logic),
            logicInit,
            address(renderer),
            rendererInit
        );

        // PRESS SETTINGS
        IERC721Press.Settings memory pressSettings = IERC721Press.Settings({
            fundsRecipient: PRESS_FUNDS_RECIPIENT,
            royaltyBPS: 250, // 2.5%
            transferable: false
        });

         // INITIALIZE PROXY
        targetPressProxy.initialize({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            database: database,
            databaseInit: databaseInit,
            settings: pressSettings                    
        });        

        _;
    }

    modifier setUpCurationStrategy_TransferableTokens() {

        // SETUP LOGIC INIT
        RolesWith721GateImmutableMetadataNoFees.RoleDetails[] memory initialRoles = 
            new RolesWith721GateImmutableMetadataNoFees.RoleDetails[](2);
        initialRoles[0].account = PRESS_ADMIN_AND_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = PRESS_MANAGER;
        initialRoles[1].role = MANAGER_ROLE;      
        mockAccessPass.mint(PRESS_USER);   
        bool initialIsPaused = false;     
        bool initialIsTokenDataImmutable = true;
        bytes memory logicInit = abi.encode(address(mockAccessPass), initialIsPaused, initialIsTokenDataImmutable, initialRoles);

        // SETUP RENDERER INIT
        string memory contractUriImagePath = "ipfs://THIS_COULD_BE_CONTRACT_URI_IMAGE_PATH";
        bytes memory rendererInit = abi.encode(contractUriImagePath);

        // SETUP DATABASE INIT
        bytes memory databaseInit = abi.encode(
            address(logic),
            logicInit,
            address(renderer),
            rendererInit
        );

        // PRESS SETTINGS
        IERC721Press.Settings memory pressSettings = IERC721Press.Settings({
            fundsRecipient: PRESS_FUNDS_RECIPIENT,
            royaltyBPS: 250, // 2.5%
            transferable: true
        });

         // INITIALIZE PROXY
        targetPressProxy.initialize({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            database: database,
            databaseInit: databaseInit,
            settings: pressSettings                    
        });        

        _;
    }    

    // LISTING ENCODING HELPERS

    function encodeListing(CurationDatabaseV1.Listing memory _listing) public pure returns (bytes memory) {
        return abi.encode(
            _listing.chainId,
            _listing.tokenId,
            _listing.listingAddress,
            _listing.hasTokenId
        );
    }     

    function encodeListingArray(CurationDatabaseV1.Listing[] memory _listings) public returns (bytes memory) {
        bytes[] memory encodedListings = new bytes[](_listings.length);
        for (uint i = 0; i < _listings.length; i++) {
            encodedListings[i] = encodeListing(_listings[i]);
        }
        return abi.encode(encodedListings);
    }        

    /* Archiving internal helper that utilized encodePacked to more efficiently encode data
    function encodeListings(CurationDatabaseV1.Listing[] memory _listings) public pure returns (bytes memory) {
        bytes memory encodedListings;
        for (uint i = 0; i < _listings.length; ++i) {
            encodedListings = bytes.concat(
                encodedListings, 
                abi.encodePacked(
                    _listings[i].chainId,
                    _listings[i].tokenId,
                    _listings[i].listingAddress,
                    _listings[i].hasTokenId                    
                )
            );
        }
        return encodedListings;
    }        
    */
}
