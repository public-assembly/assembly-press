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

    // mintWithData test doubles as a test for making sure data is being encoded/decoded correctly
    //      data passing is being tested with curation logic in this test
    function test_mintWithData() public setUpPressCurationLogic {      
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();    
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].listingAddress = address(0x333);
        listings[1].tokenId = 0;
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 5;        
        bytes memory encodedListings = encodeListingArray(listings);        
        erc721Press.mintWithData(2, encodedListings);

        /* not sure how to test that contractURI + tokenURI are working correctly -- so check console logs for proof */
        // console2.log(erc721Press.contractURI());
        // console2.log(erc721Press.tokenURI(1));

        require(erc721Press.ownerOf(1) == CURATOR_1, "mint recipient incorrect");
        require(erc721Press.ownerOf(2) == CURATOR_1, "mint recipient incorrect");
        require(ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press)).length == 2, "listings added incorrectly");  

        // cache array of active elistngs
        (ICurationLogic.Listing[] memory arrayOfListings) = ICurationLogic(address(erc721Press.getLogic())).getListings(address(erc721Press));

        // scoped assignment of variables to use for tests
        {
            (
                address listingAddress_1,
                uint128 tokenId_1,
                int32 sortOrder_1,
                bool hasTokenId_1,
                uint128 chainId_1           
            ) = (
                arrayOfListings[0].listingAddress,
                arrayOfListings[0].tokenId,
                arrayOfListings[0].sortOrder,
                arrayOfListings[0].hasTokenId,
                arrayOfListings[0].chainId         
            );
            require(listingAddress_1 == address(0x111), "listingAddress not passed correctly");
            require(tokenId_1 == 1, "tokenId not passed correctly");
            require(sortOrder_1 == 1, "sortOrder not passed correctly");
            require(hasTokenId_1 == true, "hasToken not passed correctly");
            require(chainId_1 == 1, "chainId not passed correctly");
        }

        // scoped assignment of variables to use for tests
        {
            (
                address listingAddress_2,
                uint128 tokenId_2,
                int32 sortOrder_2,
                bool hasTokenId_2,
                uint128 chainId_2            
            ) = (
                arrayOfListings[1].listingAddress,
                arrayOfListings[1].tokenId,
                arrayOfListings[1].sortOrder,
                arrayOfListings[1].hasTokenId,
                arrayOfListings[1].chainId            
            );
            require(listingAddress_2 == address(0x333), "listingAddress not passed correctly");
            require(tokenId_2 == 0, "tokenId not passed correctly");
            require(sortOrder_2 == -1, "sortOrder not passed correctly");
            require(hasTokenId_2 == false, "hasToken not passed correctly");
            require(chainId_2 == 5, "chainId not passed correctly");            
        }        
 
        vm.stopPrank();
        vm.startPrank(CURATOR_2);

        ICurationLogic.Listing[] memory listings_2 = new ICurationLogic.Listing[](1);            
        listings_2[0].listingAddress = address(0x444);
        listings_2[0].tokenId = 0;
        listings_2[0].sortOrder = 3;
        listings_2[0].hasTokenId = false;
        listings_2[0].chainId = 4;          
        bytes memory encodedListings_2 = encodeListingArray(listings_2);
        erc721Press.mintWithData(1, encodedListings_2);
        require(erc721Press.ownerOf(3) == CURATOR_2, "mint recipient incorrect");


        // Basic Metadata tests
        // contractURI
        // {"name": "Press Test","description": "This curation contract is owned by 0x0000000000000000000000000000000000000001\n\nThe tokens in this collection provide proof-of-curation and are non-transferable.\n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg=="}
        assertEq("data:application/json;base64,eyJuYW1lIjogIlByZXNzIFRlc3QiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIGN1cmF0aW9uIGNvbnRyYWN0IGlzIG93bmVkIGJ5IDB4MDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMVxuXG5UaGUgdG9rZW5zIGluIHRoaXMgY29sbGVjdGlvbiBwcm92aWRlIHByb29mLW9mLWN1cmF0aW9uIGFuZCBhcmUgbm9uLXRyYW5zZmVyYWJsZS5cblxuVGhpcyBjdXJhdGlvbiBwcm90b2NvbCBpcyBhIHByb2plY3Qgb2YgUHVibGljIEFzc2VtYmx5LlxuXG5UbyBsZWFybiBtb3JlLCB2aXNpdDogaHR0cHM6Ly9wdWJsaWMtLS1hc3NlbWJseS5jb20vIiwiaW1hZ2UiOiAiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCMmFXVjNRbTk0UFNJd0lEQWdOekl3SURjeU1DSWdlRzFzYm5NOUltaDBkSEE2THk5M2QzY3Vkek11YjNKbkx6SXdNREF2YzNabklpQjNhV1IwYUQwaU56SXdJaUJvWldsbmFIUTlJamN5TUNJK1BISmxZM1FnZUQwaU1DSWdlVDBpTUNJZ2QybGtkR2c5SWpjeU1DSWdhR1ZwWjJoMFBTSTNNakFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3d6TUNVcElpQXZQanh5WldOMElIZzlJak13SWlCNVBTSTVPQ0lnZDJsa2RHZzlJall3TUNJZ2FHVnBaMmgwUFNJMk1EQWlJSE4wZVd4bFBTSm1hV3hzT2lCb2Myd29NekUzTERJMUpTdzFNQ1VwSWlBdlBqeHlaV04wSUhnOUlqWXdJaUI1UFNJeE9EQWlJSGRwWkhSb1BTSTBPREFpSUdobGFXZG9kRDBpTkRnd0lpQnpkSGxzWlQwaVptbHNiRG9nYUhOc0tETXhOeXd5TlNVc056QWxLU0lnTHo0OGNtVmpkQ0I0UFNJNU1DSWdlVDBpTWpjd0lpQjNhV1IwYUQwaU5qQWlJR2hsYVdkb2REMGlOakFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3czTUNVcElpQXZQand2YzNablBnPT0ifQ==", erc721Press.contractURI());
        // tokenURI
        // {"name": "Curation Receipt #1","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000004\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"contract": "0x0000000000000000000000000000000000000111","tokenId": "1","curator": "0x0000000000000000000000000000000000000004","sortOrder": "1","hasTokenId": "true","chainId": "1"}}
        assertEq("data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzEiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA0XG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMTExIiwidG9rZW5JZCI6ICIxIiwiY3VyYXRvciI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDQiLCJzb3J0T3JkZXIiOiAiMSIsImhhc1Rva2VuSWQiOiAidHJ1ZSIsImNoYWluSWQiOiAiMSJ9fQ==", erc721Press.tokenURI(1));
        // {"name": "Curation Receipt #2","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000004\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"contract": "0x0000000000000000000000000000000000000333","tokenId": "0","curator": "0x0000000000000000000000000000000000000004","sortOrder": "-1","hasTokenId": "false","chainId": "5"}}
        assertEq("data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzIiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA0XG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMzMzIiwidG9rZW5JZCI6ICIwIiwiY3VyYXRvciI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDQiLCJzb3J0T3JkZXIiOiAiLTEiLCJoYXNUb2tlbklkIjogImZhbHNlIiwiY2hhaW5JZCI6ICI1In19", erc721Press.tokenURI(2));
        // {"name": "Curation Receipt #3","description": "This non-transferable NFT represents a listing curated by 0x0000000000000000000000000000000000000005\n\nYou can remove this record of curation by burning the NFT. \n\nThis curation protocol is a project of Public Assembly.\n\nTo learn more, visit: https://public---assembly.com/","image": "data:image/svg+xml;base64,PHN2ZyB2aWV3Qm94PSIwIDAgNzIwIDcyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIiB3aWR0aD0iNzIwIiBoZWlnaHQ9IjcyMCI+PHJlY3QgeD0iMCIgeT0iMCIgd2lkdGg9IjcyMCIgaGVpZ2h0PSI3MjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSwzMCUpIiAvPjxyZWN0IHg9IjMwIiB5PSI5OCIgd2lkdGg9IjYwMCIgaGVpZ2h0PSI2MDAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw1MCUpIiAvPjxyZWN0IHg9IjYwIiB5PSIxODAiIHdpZHRoPSI0ODAiIGhlaWdodD0iNDgwIiBzdHlsZT0iZmlsbDogaHNsKDMxNywyNSUsNzAlKSIgLz48cmVjdCB4PSI5MCIgeT0iMjcwIiB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHN0eWxlPSJmaWxsOiBoc2woMzE3LDI1JSw3MCUpIiAvPjwvc3ZnPg==","properties": {"contract": "0x0000000000000000000000000000000000000444","tokenId": "0","curator": "0x0000000000000000000000000000000000000005","sortOrder": "3","hasTokenId": "false","chainId": "4"}}
        assertEq("data:application/json;base64,eyJuYW1lIjogIkN1cmF0aW9uIFJlY2VpcHQgIzMiLCJkZXNjcmlwdGlvbiI6ICJUaGlzIG5vbi10cmFuc2ZlcmFibGUgTkZUIHJlcHJlc2VudHMgYSBsaXN0aW5nIGN1cmF0ZWQgYnkgMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDA1XG5cbllvdSBjYW4gcmVtb3ZlIHRoaXMgcmVjb3JkIG9mIGN1cmF0aW9uIGJ5IGJ1cm5pbmcgdGhlIE5GVC4gXG5cblRoaXMgY3VyYXRpb24gcHJvdG9jb2wgaXMgYSBwcm9qZWN0IG9mIFB1YmxpYyBBc3NlbWJseS5cblxuVG8gbGVhcm4gbW9yZSwgdmlzaXQ6IGh0dHBzOi8vcHVibGljLS0tYXNzZW1ibHkuY29tLyIsImltYWdlIjogImRhdGE6aW1hZ2Uvc3ZnK3htbDtiYXNlNjQsUEhOMlp5QjJhV1YzUW05NFBTSXdJREFnTnpJd0lEY3lNQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JaUIzYVdSMGFEMGlOekl3SWlCb1pXbG5hSFE5SWpjeU1DSStQSEpsWTNRZ2VEMGlNQ0lnZVQwaU1DSWdkMmxrZEdnOUlqY3lNQ0lnYUdWcFoyaDBQU0kzTWpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3ek1DVXBJaUF2UGp4eVpXTjBJSGc5SWpNd0lpQjVQU0k1T0NJZ2QybGtkR2c5SWpZd01DSWdhR1ZwWjJoMFBTSTJNREFpSUhOMGVXeGxQU0ptYVd4c09pQm9jMndvTXpFM0xESTFKU3cxTUNVcElpQXZQanh5WldOMElIZzlJall3SWlCNVBTSXhPREFpSUhkcFpIUm9QU0kwT0RBaUlHaGxhV2RvZEQwaU5EZ3dJaUJ6ZEhsc1pUMGlabWxzYkRvZ2FITnNLRE14Tnl3eU5TVXNOekFsS1NJZ0x6NDhjbVZqZENCNFBTSTVNQ0lnZVQwaU1qY3dJaUIzYVdSMGFEMGlOakFpSUdobGFXZG9kRDBpTmpBaUlITjBlV3hsUFNKbWFXeHNPaUJvYzJ3b016RTNMREkxSlN3M01DVXBJaUF2UGp3dmMzWm5QZz09IiwicHJvcGVydGllcyI6IHsiY29udHJhY3QiOiAiMHgwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwNDQ0IiwidG9rZW5JZCI6ICIwIiwiY3VyYXRvciI6ICIweDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDUiLCJzb3J0T3JkZXIiOiAiMyIsImhhc1Rva2VuSWQiOiAiZmFsc2UiLCJjaGFpbklkIjogIjQifX0=", erc721Press.tokenURI(3));
    }

    function test_burn() public setUpPressCurationLogic {
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();        
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](2);        
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].listingAddress = address(0x333);
        listings[1].tokenId = 0;
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = encodeListingArray(listings);    
        erc721Press.mintWithData(2, encodedListings);
        require(erc721Press.ownerOf(1) == CURATOR_1, "minted incorrectly");    
        vm.stopPrank();
        vm.startPrank(CURATOR_2);
        // should revert because CURATOR_2 is not token owner or admin
        vm.expectRevert(abi.encodeWithSignature("No_Burn_Access()"));  
        erc721Press.burn(1);
        vm.stopPrank();
        vm.startPrank(CURATOR_1);
        // should NOT revert because CURATOR_1 is token owner
        erc721Press.burn(1);
        require(erc721Press.balanceOf(CURATOR_1) == 1, "burn not functioning correctly");     
        // should revert since token 2 has been burned
        vm.expectRevert();
        erc721Press.ownerOf(1);
        vm.stopPrank();
        vm.startPrank(INITIAL_OWNER);
        // should NOT revert because INITIAL_OWNER has admin role, even though is not token owner
        erc721Press.burn(2);
        require(erc721Press.balanceOf(CURATOR_1) == 0, "burn not functioning correctly");
        vm.expectRevert();
        erc721Press.ownerOf(2);        
    }

    function test_soulbound() public setUpPressCurationLogic {
        vm.startPrank(INITIAL_OWNER);  
        curationLogic.setCurationPaused(address(erc721Press), false);
        vm.stopPrank();                
        vm.startPrank(CURATOR_1);
        ICurationLogic.Listing[] memory listings = new ICurationLogic.Listing[](1);        
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        bytes memory encodedListings = encodeListingArray(listings);    
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
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].listingAddress = address(0x333);
        listings[1].tokenId = 0;
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = encodeListingArray(listings);    
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
        listings[0].listingAddress = address(0x111);
        listings[0].tokenId = 1;
        listings[0].sortOrder = 1;
        listings[0].hasTokenId = true;
        listings[0].chainId = 1;
        listings[1].listingAddress = address(0x333);
        listings[1].tokenId = 0;
        listings[1].sortOrder = -1;
        listings[1].hasTokenId = false;
        listings[1].chainId = 1;        
        bytes memory encodedListings = encodeListingArray(listings);    
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

    function test_transfer() public setUpPressCurationLogic {
        vm.startPrank(FUNDS_RECIPIENT);
        // expect revert on transfer because msg.sender is not owner
        vm.expectRevert(abi.encodeWithSignature("ONLY_OWNER()"));
        erc721Press.transferOwnership(ADMIN);
        vm.stopPrank();
        vm.startPrank(INITIAL_OWNER);
        // transfer should go through since being called from contract owner
        erc721Press.transferOwnership(FUNDS_RECIPIENT);
        require(erc721Press.owner() == FUNDS_RECIPIENT, "ownership not transferred correctly");
    }
}