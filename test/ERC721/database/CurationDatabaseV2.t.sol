// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";

import {IERC721Press} from "../../../src/core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "../../../src/core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {CurationDatabaseV2} from "../../../src/strategies/curation/database/CurationDatabaseV2.sol";
import {ERC721Press} from "../../../src/core/token/ERC721/ERC721Press.sol";
import {ERC721PressFactory} from "../../../src/core/token/ERC721/ERC721PressFactory.sol";
import {IERC5192} from "../../../src/core/token/ERC721/interfaces/IERC5192.sol";

import {RolesWith721GateImmutableMetadataNoFees} from "../../../src/strategies/curation/logic/RolesWith721GateImmutableMetadataNoFees.sol";
import {CurationRendererV1} from "../../../src/strategies/curation/renderer/CurationRendererV1.sol";

import {MockERC721} from "../utils/mocks/MockERC721.sol";
import {MockRenderer} from "../utils/mocks/MockRenderer.sol";
import {MockLogic} from "../utils/mocks/MockLogic.sol";

import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract CurationDatabaseV2Test is Test {  

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
    RolesWith721GateImmutableMetadataNoFees public logic = new RolesWith721GateImmutableMetadataNoFees();
    CurationRendererV1 public renderer = new CurationRendererV1();    

    function setUp() public {        
        primaryOwner = address(0x111);
        secondaryOwner = address(0x222);
        ERC721Press erc721PressImpl = new ERC721Press();        
        CurationDatabaseV2 databaseImpl = new CurationDatabaseV2(primaryOwner, secondaryOwner);
        // deploy factory impl
        ERC721PressFactory erc721Factory = new ERC721PressFactory(
            address(payable(erc721PressImpl)),
            address(databaseImpl)
        );

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

        // GRANT FACTORY OFFICIAL STATUS
        vm.startPrank(primaryOwner);
        databaseImpl.setOfficialFactory(address(erc721Factory));
        vm.stopPrank();

        targetPressProxy = ERC721Press(payable(erc721Factory.createPress({
            name: "Public Assembly",
            symbol: "PA",
            initialOwner: PRESS_ADMIN_AND_OWNER,
            databaseInit: databaseInit,
            settings: pressSettings      
        })));
    }


    function test_mintWithData() public {
        vm.startPrank(PRESS_ADMIN_AND_OWNER);       
        CurationDatabaseV2.Listing[] memory listings = new CurationDatabaseV2.Listing[](1) ;        
        listings[0].chainId = 1;       
        listings[0].tokenId = 3;      
        listings[0].listingAddress = address(0x12345);       
        listings[0].hasTokenId = 1;       
        bytes memory encodedListings = abi.encodePacked(
            listings[0].chainId,
            listings[0].tokenId,
            listings[0].listingAddress,
            listings[0].hasTokenId
        );
        // bytes memory blankData = new bytes(0);
        // targetPressProxy.mintWithData(1, blankData);
        targetPressProxy.mintWithData(1, encodedListings);
        require(targetPressProxy.balanceOf(PRESS_ADMIN_AND_OWNER) == 1, "mint not functioning correctly");   
    } 
}