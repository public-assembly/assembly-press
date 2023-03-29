// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC721Press} from "../../../src/token/ERC721/ERC721Press.sol";
import {ERC721PressProxy} from "../../../src/token/ERC721/core/proxy/ERC721PressProxy.sol";
import {IERC721Press} from "../../../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {ERC721PressFactory} from "../../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721PressFactoryProxy} from "../../../src/token/ERC721/core/proxy/ERC721PressFactoryProxy.sol";

import {CurationLogic} from "../../../src/token/ERC721/curation/logic/CurationLogic.sol";
import {CurationMetadataRenderer} from "../../../src/token/ERC721/curation/metadata/CurationMetadataRenderer.sol";
import {OpenAccess} from "../../../src/token/ERC721/curation/access/OpenAccess.sol";
import {HybridAccess} from "../../../src/token/ERC721/curation/access/HybridAccess.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";

import { MockERC721 } from "../mocks/MockERC721.sol";

contract ERC721PressConfig is Test {
    address public constant INITIAL_OWNER = address(0x01);
    address public constant FUNDS_RECIPIENT = address(0x02);
    address public constant ADMIN = address(0x03);
    address public constant CURATOR_1 = address(0x04);
    address public constant CURATOR_2 = address(0x05);
    /* ===== DEFAULT CONFIG INIT INPUTS ===== */
    uint64 maxSupply = type(uint64).max;    

    ERC721Press erc721Press;
    address public erc721PressImpl;

    /* CURATION INIT */
    bool initialPauseState = true;
    // Deploy the CurationLogic contract
    CurationLogic public curationLogic = new CurationLogic();
    // Deploy the CurationMetadataRenderer contract
    CurationMetadataRenderer public curationRenderer = new CurationMetadataRenderer();
    // Deploy the OpenAccess contract
    OpenAccess public openAccess = new OpenAccess();
    bytes curLogicInit = abi.encode(initialPauseState, openAccess, "");
    // Deploy the HybridAccess contract
    HybridAccess public hybridAccess = new HybridAccess();
    // set up types for role based curation access control init
    uint8 constant ADMIN_ROLE = 3;
    uint8 constant MANAGER_ROLE = 2;
    uint8 constant NO_ROLE = 0;    
    // struct RoleDetails {
    //     address account;
    //     uint8 role;
    // } 
    // deploy mock curation pass
    MockERC721 public mockCurationPass;

    /***** FACTORY SETUP ******/
    ERC721PressFactory public erc721Factory;
    ERC721Press public curationContract;

    // Set up called before each test
    function setUp() public {
        // Deploy an ERC721Press instance
        erc721PressImpl = address(new ERC721Press());

        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC721PressProxy(erc721PressImpl, "")));

        erc721Press = ERC721Press(pressProxy);        
    }

    modifier setUpPressCurationLogic() {
        // set up configuration
        IERC721Press.Configuration memory configuration = IERC721Press.Configuration({
            fundsRecipient: payable(FUNDS_RECIPIENT),
            maxSupply: maxSupply,
            royaltyBPS: 1000,
            primarySaleFeeRecipient: payable(FUNDS_RECIPIENT),
            primarySaleFeeBPS: 1000
        });

        // initialize admin + manager roles
        HybridAccess.RoleDetails[] memory initialRoles = new HybridAccess.RoleDetails[](2);
        initialRoles[0].account = INITIAL_OWNER;
        initialRoles[0].role = ADMIN_ROLE;
        initialRoles[1].account = FUNDS_RECIPIENT;
        initialRoles[1].role = MANAGER_ROLE;      

        // mint curation pass token to curator
        mockCurationPass = new MockERC721();
        mockCurationPass.mint(CURATOR_1);        
        mockCurationPass.mint(CURATOR_2);        

        bytes memory curLogicInit2 = abi.encode(initialPauseState, hybridAccess, abi.encode(address(mockCurationPass), initialRoles));        

         // Initialize the proxy
        erc721Press.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _logic: curationLogic,
            _logicInit: curLogicInit2,
            _renderer: curationRenderer,
            _rendererInit: "",
            _soulbound: true,            
            _configuration: configuration                        
        });

        _;
    }    

    // modifier setUpPressDefaultLogic() {
    //      // Initialize the proxy
    //     erc721Press.initialize({
    //         _contractName: "Press Test",
    //         _contractSymbol: "TEST",
    //         _initialOwner: INITIAL_OWNER,
    //         _fundsRecipient: payable(FUNDS_RECIPIENT),
    //         _maxSupply: maxSupply,
    //         _royaltyBPS: 1000,
    //         _logic: defaultLogic,
    //         _logicInit: defaultLogicInit,
    //         _renderer: mockRenderer,
    //         _rendererInit: defaultRendererInit,
    //         _primarySaleFeeBPS: 1000,
    //         _primarySaleFeeRecipient: payable(FUNDS_RECIPIENT),
    //         _soulbound: 1 // 1 = soulbound
    //     });

    //     _;
    // }
}
