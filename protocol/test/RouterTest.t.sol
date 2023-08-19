// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {Router} from "../src/core/router/Router.sol";
import {Factory} from "../src/core/factory/Factory.sol";
import {IFactory} from "../src/core/factory/interfaces/IFactory.sol";
import {Press} from "../src/core/press/Press.sol";
import {PressProxy} from "../src/core/press/proxy/PressProxy.sol";
import {IPress} from "../src/core/press/interfaces/IPress.sol";
import {IPressTypesV1} from "../src/core/press/types/IPressTypesV1.sol";
import {MockLogic} from "./mocks/logic/MockLogic.sol";
import {MockRenderer} from "./mocks/renderer/MockRenderer.sol";

contract RouterTest is Test {

    // TYPES
    struct Inputs {
        string pressName; 
        address initialOwner;
        address logic;
        bytes logicInit;
        address renderer;
        bytes rendererInit;
        IPressTypesV1.AdvancedSettings advancedSettings;
    }    

    struct Listing {
        uint256 chainId;
        uint256 tokenId;
        address listing;
        bool hasTokenId;
    }    

    // PUBLIC TEST VARIABLES
    Router router;
    Factory factory;
    Press press;
    address feeRecipient = address(0x999);
    uint256 fee = 0.0005 ether;    
    MockLogic logic;
    MockRenderer renderer;
    address admin = address(0x123);

    // Set up called before each test
    function setUp() public virtual {
        router = new Router();
        press = new Press(feeRecipient, fee);
        factory = new Factory(address(router), address(press));
        logic = new MockLogic();
        renderer = new MockRenderer();
        
        address[] memory factoryToRegister = new address[](1);
        factoryToRegister[0] = address(factory);
        bool[] memory statusToRegister = new bool[](1);
        statusToRegister[0] = true;        
        router.registerFactories(factoryToRegister, statusToRegister);
    }  

    function test_factory() public {

        IPressTypesV1.AdvancedSettings memory settings = IPressTypesV1.AdvancedSettings({
            fundsRecipient: admin,
            royaltyBPS: 0,
            transferable: false, // non transferable tokens
            fungible: false // non fungible tokens
        });
        Inputs memory inputs = Inputs({
            pressName: "First Press",
            initialOwner: admin,
            logic: address(logic),
            logicInit: new bytes(0),
            renderer: address(renderer),
            rendererInit: new bytes(0),
            advancedSettings: settings
        });
        bytes memory encodedInputs = abi.encode(inputs);

        vm.prank(admin);
        address newPress = router.setup(address(factory), encodedInputs); 
        require(router.pressRegistry(newPress) == true, "press not registered correctly");
        vm.prank(admin);
        // should revert because factory isnt registered
        vm.expectRevert(abi.encodeWithSignature("Invalid_Factory()"));
        router.setup(address(0x123), encodedInputs);
    }

    function test_storeTokenData() public payable {
        Press activePress = Press(payable(createGenericPress()));

        bytes[] memory bytesArray = new bytes[](1);
        // bytesArray[0] = abi.encode("ipfsURI/");
        bytesArray[0] = abi.encode(Listing({
            chainId: 1,
            tokenId: 1,
            listing: address(0x1),
            hasTokenId: true
        }));
        bytes memory encodedBytesArray = abi.encode(bytesArray);      

        uint256 fees = activePress.getFees(bytesArray.length);
        vm.deal(admin, 1 ether);
        vm.prank(admin);
        router.storeTokenData{value: fees}(address(activePress), encodedBytesArray);        
        require(admin.balance == 1 ether - fees, "fees not correct");
        require(feeRecipient.balance == fees, "fees not correct");

        vm.prank(admin);
        // should revert because no msg.value sent for fees
        vm.expectRevert(abi.encodeWithSignature("Incorrect_Msg_Value()"));
        router.storeTokenData(address(activePress), encodedBytesArray);        

        vm.prank(admin);
        // should revert because press doesnt exist
        vm.expectRevert(abi.encodeWithSignature("Invalid_Press()"));
        router.storeTokenData(address(0x123), encodedBytesArray);
        
        vm.prank(admin);
        // should revert because cant call press directly if not router
        vm.expectRevert(abi.encodeWithSignature("Sender_Not_Router()"));
        activePress.storeTokenData(admin, encodedBytesArray);
    }

    function createGenericPress() public returns (address) {
        IPressTypesV1.AdvancedSettings memory settings = IPressTypesV1.AdvancedSettings({
            fundsRecipient: admin,
            royaltyBPS: 0,
            transferable: false, // non transferable tokens
            fungible: false // non fungible tokens
        });
        Inputs memory inputs = Inputs({
            pressName: "First Press",
            initialOwner: admin,
            logic: address(logic),
            logicInit: new bytes(0),
            renderer: address(renderer),
            rendererInit: new bytes(0),
            advancedSettings: settings
        });        
        bytes memory encodedInputs = abi.encode(inputs);     
        return router.setup(address(factory), encodedInputs);   
    }
}
