// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC721PressConfig} from "./utils/ERC721PressConfig.sol";

import {IERC721PressFactory} from "../../src/token/ERC721/core/interfaces/IERC721PressFactory.sol";
import {IERC721Press} from "../../src/token/ERC721/core/interfaces/IERC721Press.sol";
import {ERC721PressFactoryProxy} from "../../src/token/ERC721/core/proxy/ERC721PressFactoryProxy.sol";
import {ERC721PressFactory} from "../../src/token/ERC721/ERC721PressFactory.sol";
import {ERC721Press} from "../../src/token/ERC721/ERC721Press.sol";

import {HybridAccess} from "../../src/token/ERC721/strategies//curation/access/HybridAccess.sol";
import {OpenAccess} from "../../src/token/ERC721/strategies//curation/access/OpenAccess.sol";
import {ICurationLogic} from "../../src/token/ERC721/strategies//curation/interfaces/ICurationLogic.sol";
import {CurationLogic} from "../../src/token/ERC721/strategies//curation/logic/CurationLogic.sol";
import {IERC5192} from "../../src/token/ERC721/core/interfaces/IERC5192.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import {MockERC721} from "./mocks/MockERC721.sol";

contract ERC721PressTest is ERC721PressConfig {

    function test_initialize() public setUpPressCurationLogic {
        
        require(keccak256(bytes(erc721Press.name())) == keccak256(bytes("Press Test")), "incorrect name");
        require(keccak256(bytes(erc721Press.symbol())) == keccak256(bytes("TEST")), "incorrect symbol");
        require(erc721Press.owner() == INITIAL_OWNER, "owner incorrect");
        require(curationLogic.isInitialized(address(erc721Press)) == true, "incorrect initialization");
        require(hybridAccess.curatorGateInfo(address(erc721Press)) == address(mockCurationPass), "incorrect gate");
        require(curationLogic.isPaused(address(erc721Press)) == true, "incorrect paue state");
        require(mockCurationPass.balanceOf(CURATOR_1) == 1 && mockCurationPass.balanceOf(CURATOR_2) == 1, "not incorrect balance");

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

        // check to make sure contract cant be reinitialized
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
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

        // check to see if supportsInterface work
        require(erc721Press.supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support");
        require(erc721Press.supportsInterface(type(IERC5192).interfaceId) == true, "doesn't support");

    }

    function test_rolesAndGate() public setUpPressCurationLogic {
        require(hybridAccess.getAccessLevel(address(erc721Press), INITIAL_OWNER) == 3, "admin set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == 2, "manager set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), CURATOR_1) == 1, "curation pass set incorrectly");
        require(hybridAccess.getAccessLevel(address(erc721Press), address(0x12345)) == 0, "total access control set incorrectly");
        vm.startPrank(INITIAL_OWNER);
        // set up new roles
        HybridAccess.RoleDetails[] memory newRoles = new HybridAccess.RoleDetails[](1);
        newRoles[0].account = FUNDS_RECIPIENT;
        newRoles[0].role = ADMIN_ROLE;

        (uint8 role) = hybridAccess.roleInfo(address(erc721Press), INITIAL_OWNER);

        hybridAccess.grantRoles(address(erc721Press), newRoles);
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == 3, "admin set incorrectly");

        address[] memory accountsToRevoke = new address[](1);
        accountsToRevoke[0] = FUNDS_RECIPIENT;
        hybridAccess.revokeRoles(address(erc721Press), accountsToRevoke);
        require(hybridAccess.getAccessLevel(address(erc721Press), FUNDS_RECIPIENT) == NO_ROLE, "admin role not revoked");
        vm.stopPrank();

        address newCuratorGate = address(0x777);

        vm.startPrank(FUNDS_RECIPIENT);
        // expect revert because FUNDS_RECIPIENT is not an admin at this point in the code
        vm.expectRevert();
        hybridAccess.setCuratorGate(address(erc721Press), newCuratorGate);
        vm.stopPrank();
        
        vm.startPrank(INITIAL_OWNER);
        hybridAccess.setCuratorGate(address(erc721Press), newCuratorGate);
        require(hybridAccess.curatorGateInfo(address(erc721Press)) == newCuratorGate, "gate change incorrect");
    }       

    function test_unpause() public setUpPressCurationLogic {
        vm.startPrank(CURATOR_1);
        // expect revert because CURATOR address doesnt have access to adjust pause state
        vm.expectRevert();
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();
        vm.startPrank(INITIAL_OWNER);
        // expect revert because trying to set pause to same state it already is
        vm.expectRevert();
        curationLogic.setCurationPaused(address(erc721Press), true);
        // next call should pass because its being called by an admin and updated pause correctly
        curationLogic.setCurationPaused(address(erc721Press), false);
        require(curationLogic.isPaused(address(erc721Press)) == false, "not correct");
    }

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData() public setUpPressCurationLogic {      
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
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);

        /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
        // console2.log(erc721Press.contractURI());
        // console2.log(erc721Press.tokenURI(1));

        require(ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 2).curator == CURATOR_1, "listing added incorrectly");
        require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");        
        vm.stopPrank();
        // switching personas to test getListingsForCurator function
        vm.startPrank(CURATOR_2);
        ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
        listings_2[0].curatedAddress = address(0x444);
        listings_2[0].selectedTokenId = 0;
        listings_2[0].curator = CURATOR_2;
        listings_2[0].curationTargetType = 1; // curationType = NFT Contract
        listings_2[0].sortOrder = 3;
        listings_2[0].hasTokenId = false;
        listings_2[0].chainId = 4;          
        bytes memory encodedListings_2 = abi.encode(listings_2);
        erc721Press.mintWithData(1, encodedListings_2);
        require(erc721Press.ownerOf(3) == CURATOR_2, "minted incorrectly");
    }

    function test_burn() public setUpPressCurationLogic {
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
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(2, encodedListings);
        require(erc721Press.ownerOf(2) == CURATOR_1, "minted incorrectly");        
        erc721Press.burn(2);
        require(erc721Press.balanceOf(CURATOR_1) == 1, "burn not functioning correctly");     
        // should revert since token 2 has been burned
        vm.expectRevert();
        erc721Press.ownerOf(2);
    }

    function test_soulbound() public setUpPressCurationLogic {
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();                
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData(1, encodedListings);
        require(erc721Press.ownerOf(1) == CURATOR_1, "minted incorrectly");        
        vm.expectRevert();
        erc721Press.safeTransferFrom(CURATOR_1, address(0x123), 1, new bytes(0));
    }

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_mintWithData_withFee() public setUpPressCurationLogicWithFee {      
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();    
        vm.deal(CURATOR_1, 0.03 ether);
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        require(CURATOR_1.balance == 0.03 ether, "incorrect balance");
        erc721Press.mintWithData{
            value: erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            )
        }(2, encodedListings);
        require(
            CURATOR_1.balance == (0.03 ether - erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            )), "incorrect balance of minter"
        );
        require(
            address(erc721Press).balance == erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            ), "incorrect balance of erc721 contract"
        );        
    }

    // mintWithData test doubles as a test for addListing call on CurationLogic 
    function test_withdraw() public setUpPressCurationLogicWithFee {      
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();    
        vm.deal(CURATOR_1, 0.03 ether);
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].curatedAddress = address(0x111);
        listings[0].selectedTokenId = 1;
        listings[0].curator = CURATOR_1;
        listings[0].curationTargetType = 4; // curationType = NFT Item
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].curatedAddress = address(0x333);
        listings[1].selectedTokenId = 0;
        listings[1].curator = CURATOR_1;
        listings[1].curationTargetType = 1; // curationType = NFT Contract
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = abi.encode(listings);
        erc721Press.mintWithData{
            value: erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            )
        }(2, encodedListings);
        require(
            address(erc721Press).balance == erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            ), "incorrect balance of erc721 contract"
        );        
        erc721Press.withdraw();
        require(
            FUNDS_RECIPIENT.balance == erc721Press.getLogic().totalMintPrice(
                address(erc721Press),
                2,
                msg.sender
            ), "incorrect balance of funds recipient"
        );     
        require(address(erc721Press).balance == 0, "incorrect balance of erc721 contract");                       
    }    

    function test_factory() public {
        
        // deploy factory impl
        erc721Factory = new ERC721PressFactory(erc721PressImpl);

        // deploy factory proxy
        ERC721PressFactoryProxy erc721PressFactoryProxy = new ERC721PressFactoryProxy(
            address(erc721Factory),
            INITIAL_OWNER,
            FUNDS_RECIPIENT
        );

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

        curationContract = ERC721Press(payable(IERC721PressFactory(address(erc721PressFactoryProxy)).createPress(
            "Movement", 
            "SYMBOL",
            INITIAL_OWNER,
            curationLogic,
            curLogicInit2,
            curationRenderer,
            "",
            true,
            configuration
        )));

        require(keccak256(bytes(curationContract.name())) == keccak256(bytes("Movement")), "incorrect name");
        require(keccak256(bytes(curationContract.symbol())) == keccak256(bytes("SYMBOL")), "incorrect symbol");
        require(address(curationContract.getLogic()) == address(curationLogic), "incorrect logic");
        require(address(curationContract.getRenderer()) == address(curationRenderer), "incorrect renderer");
        require(curationContract.isSoulbound() == true, "incorrect soulbound status");
        IERC721Press.Configuration memory configurationCheck = curationContract.getConfigDetails();
        require(configurationCheck.fundsRecipient == configuration.fundsRecipient, "incorrect config");
        require(configurationCheck.primarySaleFeeRecipient == configuration.primarySaleFeeRecipient, "incorrect config");
        require(configurationCheck.maxSupply == configuration.maxSupply, "incorrect config");
        require(configurationCheck.royaltyBPS == configuration.royaltyBPS, "incorrect config");
        require(configurationCheck.primarySaleFeeBPS == configuration.primarySaleFeeBPS, "incorrect config");
    }

    /* WIP tests in support of in progress updated curatin logic decoder written in assembly

    // function testDecodeListings() public setUpPressCurationLogic {
    //     vm.startPrank(INITIAL_OWNER);  
    //     curationLogic.setCurationPaused(address(erc721Press), false);
    //     vm.stopPrank();    
    //     vm.startPrank(CURATOR_1);

    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);

    //     listings[0] = ICurationLogic.Listing({
    //         curatedAddress: address(0x123),
    //         selectedTokenId: 1,
    //         curator: CURATOR_1,
    //         sortOrder: -1,
    //         chainId: 1,
    //         curationTargetType: 2,
    //         hasTokenId: true
    //     });

    //     listings[1] = ICurationLogic.Listing({
    //         curatedAddress: address(0x456),
    //         selectedTokenId: 2,
    //         curator: CURATOR_1,
    //         sortOrder: 1,
    //         chainId: 3,
    //         curationTargetType: 4,
    //         hasTokenId: false
    //     });

    //     // Encoding the listings manually
    //     bytes memory packedListings;
    //     for (uint256 i = 0; i < listings.length; i++) {
    //         packedListings = abi.encodePacked(
    //             packedListings,
    //             listings[i].curatedAddress,
    //             uint96(listings[i].selectedTokenId) << 224, // Manually pad the selectedTokenId
    //             listings[i].curator,
    //             int256(listings[i].sortOrder) << 224, // Manually pad the sortOrder
    //             uint256(listings[i].chainId) << 240, // Manually pad the chainId
    //             uint256(listings[i].curationTargetType) << 240, // Manually pad the curationTargetType
    //             uint8(listings[i].hasTokenId ? 1 : 0) << 248 // Manually pad the hasTokenId
    //         );
    //     }

    //     erc721Press.mintWithData(2, packedListings);

    //     // ICurationLogic.Listing[] memory decodedListings = listingEncoderDecoder.decodeListings(packedListings);

    //     // Assert.equal(decodedListings.length, listings.length, "Number of decoded listings should match the original listings");

    //     // for (uint256 i = 0; i < decodedListings.length; i++) {
    //     //     assert.equal(decodedListings[i].curatedAddress, listings[i].curatedAddress, "Decoded curatedAddress should match the original curatedAddress");
    //     //     assert.equal(decodedListings[i].selectedTokenId, listings[i].selectedTokenId, "Decoded selectedTokenId should match the original selectedTokenId");
    //     //     assert.equal(decodedListings[i].curator, listings[i].curator, "Decoded curator should match the original curator");
    //     //     assert.equal(decodedListings[i].sortOrder, listings[i].sortOrder, "Decoded sortOrder should match the original sortOrder");
    //     //     assert.equal(decodedListings[i].chainId, listings[i].chainId, "Decoded chainId should match the original chainId");
    //     //     assert.equal(decodedListings[i].curationTargetType, listings[i].curationTargetType, "Decoded curationTargetType should match the original curationTargetType");
    //     //     assert.equal(decodedListings[i].hasTokenId, listings[i].hasTokenId, "Decoded hasTokenId should match the original hasTokenId");
    //     // }
    // }

    // // mintWithData test doubles as a test for addListing call on CurationLogic 
    // function test_mintWithData_OD() public setUpPressCurationLogic {      
    //     vm.startPrank(INITIAL_OWNER);  
    //     curationLogic.setCurationPaused(address(erc721Press), false);
    //     vm.stopPrank();    
    //     vm.startPrank(CURATOR_1);
    //     ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
    //     listings[0].curatedAddress = address(0x111);
    //     listings[0].selectedTokenId = 1;
    //     listings[0].curator = CURATOR_1;
    //     listings[0].curationTargetType = 4; // curationType = NFT Item
    //     listings[0].sortOrder = 1;
    //     listings[0].hasTokenId = true;
    //     listings[0].chainId = 1;
    //     listings[1].curatedAddress = address(0x333);
    //     listings[1].selectedTokenId = 0;
    //     listings[1].curator = CURATOR_1;
    //     listings[1].curationTargetType = 1; // curationType = NFT Contract
    //     listings[1].sortOrder = -1;
    //     listings[1].hasTokenId = false;
    //     listings[1].chainId = 1;        

    //     bytes memory listing1Bytes = abi.encode(
    //         listings[0].curatedAddress,
    //         listings[0].selectedTokenId,
    //         listings[0].curator,
    //         listings[0].sortOrder,
    //         listings[0].curationTargetType,
    //         listings[0].chainId,
    //         listings[0].hasTokenId
    //     );

    //     bytes memory listing2Bytes = abi.encode(
    //         listings[1].curatedAddress,
    //         listings[1].selectedTokenId,
    //         listings[1].curator,
    //         listings[1].sortOrder,
    //         listings[1].curationTargetType,
    //         listings[1].chainId,
    //         listings[1].hasTokenId
    //     );

    //     bytes memory encodedListings = abi.encodePacked(listing1Bytes, listing2Bytes);        

    //     erc721Press.mintWithData(2, encodedListings);

    //     /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
    //     // console2.log(erc721Press.contractURI());
    //     // console2.log(erc721Press.tokenURI(1));

    //     require(ICurationLogic(address(erc721Press.getLogic())).getListing(address(erc721Press), 2).curator == CURATOR_1, "listing added incorrectly");
    //     require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");        
    //     vm.stopPrank();
    //     // switching personas to test getListingsForCurator function
    //     vm.startPrank(CURATOR_2);
    //     ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
    //     listings_2[0].curatedAddress = address(0x444);
    //     listings_2[0].selectedTokenId = 0;
    //     listings_2[0].curator = CURATOR_2;
    //     listings_2[0].curationTargetType = 1; // curationType = NFT Contract
    //     listings_2[0].sortOrder = 3;
    //     listings_2[0].hasTokenId = false;
    //     listings_2[0].chainId = 4;          
    //     bytes memory encodedListings_2 = abi.encode(listings_2);
    //     erc721Press.mintWithData(1, encodedListings_2);
    //     require(erc721Press.ownerOf(3) == CURATOR_2, "minted incorrectly");
    // }
}