// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {ERC721Press} from "../src/ERC721Press.sol";
import {PressFactory} from "../src/PressFactory.sol";
import {ERC721PressProxy} from "../src/proxy/ERC721PressProxy.sol";

import {DefaultLogic} from "../src/logic/DefaultLogic.sol";

import {MockLogic} from "./mocks/MockLogic.sol";
import {MockRenderer} from "./mocks/MockRenderer.sol";

contract PressConfig is Test {
    address public constant INITIAL_OWNER = address(0x01);
    address public constant FUNDS_RECIPIENT = address(0x02);
    address public constant ADMIN = address(0x03);


    ERC721Press pressBase;
    address public pressImpl;

    // Deploy a mock Logic contract
    MockLogic public mockLogic = new MockLogic();
    // Deploy a mock Renderer contract
    MockRenderer public mockRenderer = new MockRenderer();
    // Deploy the DefaultLogic contract
    DefaultLogic public defaultLogic = new DefaultLogic();

    // bytes defaultLogicInit = 

    // Set up called before each test
    function setUp() public {
        // Deploy a Press instance
        pressImpl = address(new ERC721Press());

        // Create a proxy for that instance
        address payable pressProxy = payable(address(new ERC721PressProxy(pressImpl, "")));

        pressBase = ERC721Press(pressProxy);
    }

    modifier setUpPressBase() {
        // Initialize the proxy
        pressBase.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _fundsRecipient: payable(FUNDS_RECIPIENT),
            _royaltyBPS: 1000,
            _logic: mockLogic,
            _logicInit: "",
            _renderer: mockRenderer,
            _rendererInit: "",
            _primarySaleFeeBPS: 1000,
            _primarySaleFeeRecipient: payable(FUNDS_RECIPIENT)
        });

        _;
    }

    modifier setUpPressDefaultLogic() {
         // Initialize the proxy
        pressBase.initialize({
            _contractName: "Press Test",
            _contractSymbol: "TEST",
            _initialOwner: INITIAL_OWNER,
            _fundsRecipient: payable(FUNDS_RECIPIENT),
            _royaltyBPS: 1000,
            _logic: defaultLogic,
            _logicInit: defaultLogicInit,
            _renderer: mockRenderer,
            _rendererInit: "",
            _primarySaleFeeBPS: 1000,
            _primarySaleFeeRecipient: payable(FUNDS_RECIPIENT)
        });

        _;
    }
}
