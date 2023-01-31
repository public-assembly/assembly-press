// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC721Press} from "../../../src/tokens/ERC721/ERC721Press.sol";
import {ERC721PressProxy} from "../../../src/tokens/ERC721/proxy/ERC721PressProxy.sol";

import {DefaultLogic} from "../../../src/tokens/ERC721/logic/DefaultLogic.sol";

import {MockLogic} from "../mocks/MockLogic.sol";
import {MockRenderer} from "../mocks/MockRenderer.sol";

contract PressConfig is Test {
    address public constant INITIAL_OWNER = address(0x01);
    address public constant FUNDS_RECIPIENT = address(0x02);
    address public constant ADMIN = address(0x03);
    /* ===== DEFAULT LOGIC INIT INPUTS ===== */
    uint256 defaultLogicMintPriceInit = 0.01 ether;
    uint64 defaultLogicMaxSupplyInit = 100;
    uint64 defaultLogicMintCapPerAddressInit = 5;    

    ERC721Press erc721Press;
    address public erc721PressImpl;

    // Deploy a mock Logic contract
    MockLogic public mockLogic = new MockLogic();
    // Deploy a mock Renderer contract
    MockRenderer public mockRenderer = new MockRenderer();
    // Deploy the DefaultLogic contract
    DefaultLogic public defaultLogic = new DefaultLogic();

    bytes defaultLogicInit = abi.encode(
        ADMIN, 
        defaultLogicMintPriceInit, 
        defaultLogicMaxSupplyInit, 
        defaultLogicMintCapPerAddressInit
    ); 
    bytes defaultRendererInit = abi.encode("youknowthevibes");

    // Set up called before each test
    function setUp() public {
        // Deploy a Press instance
        erc721PressImpl = address(new ERC721Press());

        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC721PressProxy(erc721PressImpl, "")));

        erc721Press = ERC721Press(pressProxy);
    }

    modifier setUpPressBase() {
        // Initialize the proxy
        erc721Press.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _fundsRecipient: payable(FUNDS_RECIPIENT),
            _royaltyBPS: 1000,
            _logic: mockLogic,
            _logicInit: defaultLogicInit,
            _renderer: mockRenderer,
            _rendererInit: defaultRendererInit,
            _primarySaleFeeBPS: 1000,
            _primarySaleFeeRecipient: payable(FUNDS_RECIPIENT)
        });

        _;
    }

    modifier setUpPressDefaultLogic() {
         // Initialize the proxy
        erc721Press.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _fundsRecipient: payable(FUNDS_RECIPIENT),
            _royaltyBPS: 1000,
            _logic: defaultLogic,
            _logicInit: defaultLogicInit,
            _renderer: mockRenderer,
            _rendererInit: defaultRendererInit,
            _primarySaleFeeBPS: 1000,
            _primarySaleFeeRecipient: payable(FUNDS_RECIPIENT)
        });

        _;
    }
}
