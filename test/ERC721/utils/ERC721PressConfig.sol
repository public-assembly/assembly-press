// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC721Press} from "../../../src/token/ERC721/ERC721Press.sol";
import {ERC721PressProxy} from "../../../src/token/ERC721/proxy/ERC721PressProxy.sol";
import {IERC721Press} from "../../../src/token/ERC721/interfaces/IERC721Press.sol";
import {ERC721PressCreatorV1} from "../../../src/token/ERC721/ERC721PressCreatorV1.sol";
import {ERC721PressCreatorProxy} from "../../../src/token/ERC721/proxy/ERC721PressCreatorProxy.sol";

import {CurationLogic} from "../../../src/token/ERC721/Curation/CurationLogic.sol";
import {CurationMetadataRenderer} from "../../../src/token/ERC721/Curation/CurationMetadataRenderer.sol";
import {OpenAccess} from "../../../src/token/ERC721/Curation/OpenAccess.sol";

import {DefaultLogic} from "../../../src/token/ERC721/logic/DefaultLogic.sol";
import {MockLogic} from "../mocks/MockLogic.sol";
import {MockRenderer} from "../mocks/MockRenderer.sol";

contract ERC721PressConfig is Test {
    address public constant INITIAL_OWNER = address(0x01);
    address public constant FUNDS_RECIPIENT = address(0x02);
    address public constant ADMIN = address(0x03);
    /* ===== DEFAULT LOGIC INIT INPUTS ===== */
    uint256 defaultLogicMintPriceInit = 0.01 ether;
    uint64 defaultLogicMaxSupplyInit = 100;
    uint64 defaultLogicMintCapPerAddressInit = 5;    
    /* ===== DEFAULT CONFIG INIT INPUTS ===== */
    uint64 maxSupply = type(uint64).max;

    ERC721Press erc721Press;
    address public erc721PressImpl;

    // Deploy a mock Logic contract
    MockLogic public mockLogic = new MockLogic();
    // Deploy a mock Renderer contract
    MockRenderer public mockRenderer = new MockRenderer();
    // Deploy the DefaultLogic contract
    DefaultLogic public defaultLogic = new DefaultLogic();

    /* CURATION STUFF HERE */
    bool initialPauseState = true;
    // Deploy the CurationLogic contract
    CurationLogic public curationLogic = new CurationLogic();
    // Deploy the CurationMetadataRenderer contract
    CurationMetadataRenderer public curationRenderer = new CurationMetadataRenderer();
    // Deploy the OpenAccess contract
    OpenAccess public openAccess = new OpenAccess();
    bytes curLogicInit = abi.encode(initialPauseState, openAccess, "");

    bytes defaultLogicInit = abi.encode(
        ADMIN, 
        defaultLogicMintPriceInit, 
        defaultLogicMaxSupplyInit, 
        defaultLogicMintCapPerAddressInit
    ); 
    bytes defaultRendererInit = abi.encode("youknowthevibes");

    /***** FACTORY SETUP ******/
    ERC721PressCreatorV1 public erc721Creator;
    ERC721Press public curationContract;

    // Set up called before each test
    function setUp() public {
        // Deploy an ERC721Press instance
        erc721PressImpl = address(new ERC721Press());

        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC721PressProxy(erc721PressImpl, "")));

        erc721Press = ERC721Press(pressProxy);
    }

    modifier setUpERC721PressBase() {
        
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
            _logic: mockLogic,
            _logicInit: defaultLogicInit,
            _renderer: mockRenderer,
            _rendererInit: defaultRendererInit,
            _soulbound: false,
            _configuration: configuration            
        });

        _;
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
