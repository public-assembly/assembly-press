// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {River} from "../src/core/river/River.sol";
import {Branch} from "../src/core/branch/Branch.sol";
import {IBranch} from "../src/core/branch/interfaces/IBranch.sol";
import {Channel} from "../src/core/channel/Channel.sol";
import {ChannelProxy} from "../src/core/channel/proxy/ChannelProxy.sol";
import {IChannel} from "../src/core/channel/interfaces/IChannel.sol";
import {IChannelTypesV1} from "../src/core/channel/types/IChannelTypesV1.sol";
// import {FeeRouter} from "../../../../src/core/FeeRouter.sol";
import {MockLogic} from "./mocks/logic/MockLogic.sol";
import {MockRenderer} from "./mocks/renderer/MockRenderer.sol";

contract RiverTest is Test {

    // TYPES
    struct Inputs {
        string channelName; 
        address initialOwner;
        address feeRouterImpl;
        address logic;
        bytes logicInit;
        address renderer;
        bytes rendererInit;
        IChannelTypesV1.AdvancedSettings advancedSettings;
    }    

    struct Listing {
        uint256 chainId;
        uint256 tokenId;
        address listing;
        bool hasTokenId;
    }    

    // PUBLIC TEST VARIABLES
    River river;
    Branch branch;
    Channel channel;
    MockLogic logic;
    MockRenderer renderer;
    address feeRouter;
    address admin = address(0x123);

    // Set up called before each test
    function setUp() public virtual {
        river = new River();
        channel = new Channel();
        branch = new Branch(address(river), address(channel));
        logic = new MockLogic();
        renderer = new MockRenderer();
        
        address[] memory branchToRegister = new address[](1);
        branchToRegister[0] = address(branch);
        bool[] memory statusToRegister = new bool[](1);
        statusToRegister[0] = true;        
        river.registerBranches(branchToRegister, statusToRegister);
    }  

    function test_branch() public {

        IChannelTypesV1.AdvancedSettings memory settings = IChannelTypesV1.AdvancedSettings({
            fundsRecipient: admin,
            royaltyBPS: 0,
            transferable: false, // non transferable tokens
            fungible: false // non fungible tokens
        });
        Inputs memory inputs = Inputs({
            channelName: "First Channel",
            initialOwner: admin,
            feeRouterImpl: feeRouter,
            logic: address(logic),
            logicInit: new bytes(0),
            renderer: address(renderer),
            rendererInit: new bytes(0),
            advancedSettings: settings
        });
        bytes memory encodedInputs = abi.encode(inputs);

        vm.prank(admin);
        address newChannel = river.branch(address(branch), encodedInputs); 
        require(river.channelRegistry(newChannel) == true, "channel not registered correctly");
        vm.prank(admin);
        // should revert because branch isnt registered
        vm.expectRevert(abi.encodeWithSignature("Invalid_Branch()"));
        river.branch(address(0x123), encodedInputs);
    }

    function test_storeTokenData() public {
        Channel activeChannel = Channel(payable(createGenericChannel()));

        bytes[] memory bytesArray = new bytes[](1);
        // bytesArray[0] = abi.encode("ipfsURI/");
        bytesArray[0] = abi.encode(Listing({
            chainId: 1,
            tokenId: 1,
            listing: address(0x1),
            hasTokenId: true
        }));
        bytes memory encodedBytesArray = abi.encode(bytesArray);      
        // (, uint256 fees) = feeRouter.getFees(address(0), 1);
        // vm.deal(owner, 1 ether);
        vm.prank(admin);
        river.storeTokenData(address(activeChannel), encodedBytesArray);

        vm.prank(admin);
        // should revert because channel doesnt exist
        vm.expectRevert(abi.encodeWithSignature("Invalid_Channel()"));
        river.storeTokenData(address(0x123), encodedBytesArray);
        
        vm.prank(admin);
        // should revert because cant call channel directly if not river
        vm.expectRevert(abi.encodeWithSignature("Sender_Not_River()"));
        activeChannel.storeTokenData(admin, encodedBytesArray);
    }

    function createGenericChannel() public returns (address) {
        IChannelTypesV1.AdvancedSettings memory settings = IChannelTypesV1.AdvancedSettings({
            fundsRecipient: admin,
            royaltyBPS: 0,
            transferable: false, // non transferable tokens
            fungible: false // non fungible tokens
        });
        Inputs memory inputs = Inputs({
            channelName: "First Channel",
            initialOwner: admin,
            feeRouterImpl: feeRouter,
            logic: address(logic),
            logicInit: new bytes(0),
            renderer: address(renderer),
            rendererInit: new bytes(0),
            advancedSettings: settings
        });        
        bytes memory encodedInputs = abi.encode(inputs);     
        return river.branch(address(branch), encodedInputs);   
    }
}
