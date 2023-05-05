// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";
import {ERC1155PressConfig} from "./utils/ERC1155PressConfig.sol";
import {ERC1155EditionContractLogic} from "../../src/token/ERC1155/strategies/editions/logic/ERC1155EditionContractLogic.sol";
import {ERC1155EditionTokenLogic} from "../../src/token/ERC1155/strategies/editions/logic/ERC1155EditionTokenLogic.sol";
import {ERC1155EditionRenderer} from "../../src/token/ERC1155/strategies/editions/metadata/ERC1155EditionRenderer.sol";
import {ERC1155Press} from "../../src/token/ERC1155/ERC1155Press.sol";
import {ERC1155PressFactory} from "../../src/token/ERC1155/ERC1155PressFactory.sol";
import {IERC1155PressTokenLogic} from "../../src/token/ERC1155/core/interfaces/IERC1155PressTokenLogic.sol";
import {IERC1155PressTokenRenderer} from "../../src/token/ERC1155/core/interfaces/IERC1155PressTokenRenderer.sol";
import {IERC5633} from "../../src/token/ERC1155/core/interfaces/IERC5633.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from "openzeppelin-contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

contract ERC1155PressTest is ERC1155PressConfig {

    function test_Init() public setUpERC1155PressBase {

        // check to see if contract level storage was initialized correctly
        string memory name = erc1155Press.name();
        string memory symbol = erc1155Press.symbol();
        require(keccak256(bytes(name)) == keccak256(bytes(contractName)));
        require(keccak256(bytes(symbol)) == keccak256(bytes(contractSymbol)));        
        require(erc1155Press.owner() == INITIAL_OWNER, "Default owner set wrong");
        require(erc1155Press.contractLogic() == contractLogic, "Contract logic set wrong");

        // check to make sure contract cant be reinitialized
        vm.expectRevert("Initializable: contract is already initialized");
        erc1155Press.initialize({
            _name: contractName,
            _symbol: contractSymbol,
            _initialOwner: INITIAL_OWNER,
            _contractLogic: contractLogic,
            _contractLogicInit: contractLogicInit
        });        

        // check to see if contract logic was initialized correctly
        uint16 accessRole = ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),contractAdminInit);
        (uint256 mintNewPrice, uint8 initialized) = ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).contractInfo(address(erc1155Press));
        require(accessRole == 2, "admin role was set wrong");
        require(mintNewPrice == 0.01 ether, "mintprice is wrong");
        require(initialized == 1, "initialized is wrong");              

        // check to see if contract logic interface works correctly 
        //      erc1155Press.contractLogic() returns IERC1155PressContractLogic
        //      at this point in test, INITIAL_OWNER has the ADMIN role

        // isInitialized
        require(erc1155Press.contractLogic().isInitialized(address(erc1155Press)) == true, "isInitialized incorrect");              

        // mintNewPrice
        uint256 mintQuantity = 3;
        address[] memory minters = new address[](1);
        minters[0] = RANDOM_WALLET;
        require(
            erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                RANDOM_WALLET,
                minters,
                mintQuantity
            ) == (mintNewPrice * mintQuantity), "mintNewPrice incorrect"
        );

        // canMintNew
        address[] memory recipients = new address[](1);
        recipients[0] = RANDOM_WALLET;        
        require(
            erc1155Press.contractLogic().canMintNew(
                address(erc1155Press),
                RANDOM_WALLET,
                recipients,
                mintQuantity
            ) == false, "canMintNew roles incorrect"
        );          
        require(
            erc1155Press.contractLogic().canMintNew(
                address(erc1155Press),
                INITIAL_OWNER,
                recipients,
                mintQuantity
            ) == true, "canMintNew roles incorrect"
        );     

        // canSetOwner            
        require(
            erc1155Press.contractLogic().canSetOwner(
                address(erc1155Press),
                RANDOM_WALLET
            ) == false, "canSetOwner roles incorrect"
        );          
        require(
            erc1155Press.contractLogic().canSetOwner(
                address(erc1155Press),
                INITIAL_OWNER
            ) == true, "canSetOwner roles incorrect"
        );       

        // check to see if supportsInterface work
        require(erc1155Press.supportsInterface(type(IERC2981Upgradeable).interfaceId) == true, "doesn't support");
        require(erc1155Press.supportsInterface(type(IERC5633).interfaceId) == true, "doesn't support");
        // make sure eip-5633 compliand interfaceId is supported
        require(erc1155Press.supportsInterface(0x911ec470) == true, "doesn't support");
    }

    function test_GrantRoles() public setUpERC1155PressBase {    
        /* Granting Roles */
        vm.startPrank(INITIAL_OWNER);
        address[] memory receivers = new address[](2);
        receivers[0] = ADMIN; 
        receivers[1] = MINTER; 
        uint16[] memory roles = new uint16[](2);
        roles[0] = 2; // ADMIN role 
        roles[1] = 1; // MINTER role           
        // set roles
        ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).setAccessControl(
            address(erc1155Press),
            receivers,
            roles
        );
        // check to make sure addresses have correct roles
        uint16 accessRole1 = ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),ADMIN);
        uint16 accessRole2 = ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),MINTER);
        uint16 accessRole3 = ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),RANDOM_WALLET);
        require(accessRole1 == 2 && accessRole2 == 1 && accessRole3 == 0, "roles incorrect");
        vm.stopPrank();
    }

    /* 
        CONTRACT LEVEL TESTS        
        calling functions gated by contract level logic 
    */

    function test_mintNew() public setUpERC1155PressBase {    
        
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory mintNewRecipients = new address[](2);
        mintNewRecipients[0] = ADMIN;
        mintNewRecipients[1] = MINTER;
        uint256 quantity = 1000;
        address payable fundsRecipient = payable(ADMIN);
        uint16 royaltyBPS = 10_00; // 10%
        address payable primarySaleFeeRecipient = payable(MINTER);
        uint16 primarySaleFeeBPS = 50_00; // 5%
        bool soulbound = false;
        erc1155Press.mintNew{
            value: erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            )
        }(
            mintNewRecipients,
            quantity,
            tokenLogic,
            tokenLogicInit,
            editionRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulbound
        );
        require(erc1155Press.tokenCount() == 1, "tokenCount incorrect");
        require(erc1155Press.balanceOf(ADMIN, 1) == quantity, "balanceOf incorrect");
        require(erc1155Press.balanceOf(MINTER, 1) == quantity, "balanceOf incorrect");
        require(erc1155Press.totalSupply(1) == (quantity * mintNewRecipients.length), "totalSupply incorrect");
        {
            // using scope to avoid stack to deep error
            (address royaltyRecip, uint256 royaltyAmount) = erc1155Press.royaltyInfo(1, 1 ether);
            require(royaltyRecip == fundsRecipient && royaltyAmount == (1 ether / (royaltyBPS / 100)), "royalties set up incorrectly");
        }
        // check if msg value transfferred was correct
        require(
            address(erc1155Press).balance == erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            ), "funds transferred incorrect"
        );
        // check if funds attributed to token1 were correct
        require(
            erc1155Press.tokenFundsInfo(1) == erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            ), "funds transferred incorrect"
        );        
        vm.stopPrank();

        // check that wallet without permissions cant call mintNew successfully
        vm.startPrank(RANDOM_WALLET);
        vm.deal(RANDOM_WALLET, 1 ether);
        uint256 newQuantity = 1;
        vm.expectRevert();
        erc1155Press.mintNew{
            value: 0.01 ether 
        }(
            mintNewRecipients,
            newQuantity,
            tokenLogic,
            tokenLogicInit,
            editionRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulbound
        );        
        vm.stopPrank();
    }

    function test_setOwner() public setUpERC1155PressBase {        
        vm.startPrank(INITIAL_OWNER);
        erc1155Press.setOwner(ADMIN);
        require(erc1155Press.owner() == ADMIN, "ownership transfer incorrect");
        // INITIAL_OWNER can still update owner because still has admin role, and transferOwnership is gated in this logic impl by ADMIN role
        erc1155Press.setOwner(MINTER);        
    }

    function test_upgrade() public setUpERC1155PressBase {        
        address erc1155PressImpl2;
        address erc1155PressImpl3;
        erc1155PressImpl2 = address(new ERC1155Press());                 
        erc1155PressImpl3 = address(new ERC1155Press());                 
        vm.startPrank(RANDOM_WALLET);
        // expect revert bc wallet doesnt have upgrade permissions
        vm.expectRevert();
        erc1155Press.upgradeTo(erc1155PressImpl2);
        vm.stopPrank();
        vm.startPrank(INITIAL_OWNER);       
        erc1155Press.upgradeTo(erc1155PressImpl2);        
        // testing that upgrades can be handled by admins -- not just contract owner        
        address[] memory receivers = new address[](2);
        receivers[0] = ADMIN; 
        receivers[1] = MINTER; 
        uint16[] memory roles = new uint16[](2);
        roles[0] = 2; // ADMIN role 
        roles[1] = 1; // MINTER role                   
        ERC1155EditionContractLogic(address(erc1155Press.contractLogic())).setAccessControl(
            address(erc1155Press),
            receivers,
            roles
        );
        vm.stopPrank();
        vm.startPrank(ADMIN);
        erc1155Press.upgradeTo(erc1155PressImpl3);
    }    

    /*
        TOKEN LEVEL TESTS
    */

    function test_mintNew_Deps() public setUpERC1155PressBase {    
        
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory mintNewRecipients = new address[](2);
        mintNewRecipients[0] = ADMIN;
        mintNewRecipients[1] = MINTER;
        uint256 quantity = 1000;
        address payable fundsRecipient = payable(ADMIN);
        uint16 royaltyBPS = 10_00; // 10%
        address payable primarySaleFeeRecipient = payable(MINTER);
        uint16 primarySaleFeeBPS = 5_00; // 5%
        bool soulbound = false;
        erc1155Press.mintNew{
            value: erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            )
        }(
            mintNewRecipients,
            quantity,
            tokenLogic,
            tokenLogicInit,
            editionRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulbound
        );
        uint256 tokenToCheck = erc1155Press.tokenCount();
        require(erc1155Press.getFundsRecipient(tokenToCheck) == fundsRecipient, "token info set incorrectly");
        require(erc1155Press.getTokenLogic(tokenToCheck) == tokenLogic, "token info set incorrectly");
        require(erc1155Press.getRenderer(tokenToCheck) == editionRenderer, "token info set incorrectly");
        // (address payable recipient, uint16 bps) = erc1155Press.getPrimarySaleFeeDetails(tokenToCheck);
        // require(recipient == primarySaleFeeRecipient, "token info set incorrectly");
        require(erc1155Press.isSoulbound(tokenToCheck) == soulbound, "token info set incorrectly");
        // require(bps == primarySaleFeeBPS, "token info set incorrectly");

        // token logic level checks
        (
            uint256 startTime, 
            uint256 mintExistingPrice, 
            uint256 mintCapPerAddress, 
            uint8 initialized
        ) = ERC1155EditionTokenLogic(address(erc1155Press.getTokenLogic(tokenToCheck))).tokenInfo(address(erc1155Press), tokenToCheck);
        require(startTime == startTimePast, "token initialized incorectly");
        require(mintExistingPrice == mintExistingPriceInit, "token initialized incorectly");
        require(mintCapPerAddress == type(uint256).max, "token initialized incorectly");
        require(initialized == 1, "token initialized incorectly");
        uint256 accessRole = ERC1155EditionTokenLogic(address(erc1155Press.getTokenLogic(tokenToCheck))).accessInfo(address(erc1155Press), tokenToCheck, tokenAdminInit);
        require(accessRole == 2, "token initialized incorrectly");


        // mintExistingPrice
        uint256 mintQuantity = 3;
        address[] memory minters = new address[](1);
        minters[0] = RANDOM_WALLET;
        require(
            erc1155Press.getTokenLogic(1).mintExistingPrice(
                address(erc1155Press), 
                tokenToCheck, 
                RANDOM_WALLET, 
                minters, 
                mintQuantity
            ) == (mintExistingPriceInit * mintQuantity), "mintExistingPrice incorrect:"
        );

        // canMintExisting     
        require(
            erc1155Press.getTokenLogic(1).canMintExisting(
                address(erc1155Press), 
                RANDOM_WALLET, 
                tokenToCheck, 
                minters, 
                mintQuantity
            ) == true, "cantMintExisting incorrect"
        );  
        require(
            erc1155Press.getTokenLogic(1).canMintExisting(
                address(erc1155Press), 
                tokenAdminInit, 
                tokenToCheck, 
                minters, 
                mintQuantity
            ) == true, "cantMintExisting incorrect"
        );          

        // canEditMetadata     
        require(
            erc1155Press.getTokenLogic(1).canEditMetadata(
                address(erc1155Press), 
                tokenToCheck, 
                RANDOM_WALLET
            ) == false, "canEditMetadata incorrect"
        );          
        require(
            erc1155Press.getTokenLogic(1).canEditMetadata(
                address(erc1155Press), 
                tokenToCheck, 
                tokenAdminInit
            ) == true, "canEditMetadata incorrect"
        );     

        // canUpdateConfig     
        require(
            erc1155Press.getTokenLogic(1).canUpdateConfig(
                address(erc1155Press), 
                tokenToCheck, 
                RANDOM_WALLET
            ) == false, "canUpdateConfig incorrect"
        );          
        require(
            erc1155Press.getTokenLogic(1).canUpdateConfig(
                address(erc1155Press), 
                tokenToCheck, 
                tokenAdminInit
            ) == true, "canUpdateConfig incorrect"
        );         

        // canWithdraw     
        require(
            erc1155Press.getTokenLogic(1).canWithdraw(
                address(erc1155Press), 
                tokenToCheck, 
                RANDOM_WALLET
            ) == true, "canWithdraw incorrect"
        );            
        require(
            erc1155Press.getTokenLogic(1).canUpdateConfig(
                address(erc1155Press), 
                tokenToCheck, 
                tokenAdminInit
            ) == true, "canWithdraw incorrect"
        );              

        // canBurn     
        require(
            erc1155Press.getTokenLogic(1).canBurn(
                address(erc1155Press), 
                tokenToCheck, 
                1,
                RANDOM_WALLET
            ) == false, "cant burn if not in wallet"
        );            
        require(
            erc1155Press.getTokenLogic(1).canBurn(
                address(erc1155Press), 
                tokenToCheck, 
                1001,
                ADMIN
            ) == false, "cant burn more than you have"
        );           
        require(
            erc1155Press.getTokenLogic(1).canBurn(
                address(erc1155Press), 
                tokenToCheck, 
                1000,
                ADMIN
            ) == true, "token initialized incorrectly"
        );                            

        // token level renderer checks
        (string memory uri) = ERC1155EditionRenderer(address(erc1155Press.getRenderer(tokenToCheck))).tokenUriInfo(address(erc1155Press), tokenToCheck);
        require(keccak256(bytes(uri)) == keccak256(bytes(exampleString1)), "uri not initd correctly");
    }


    function test_mintExisting() public setUpERC1155PressBase setUpExistingMint(1) {        
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory recips = new address[](2);
        recips[0] = address(0x666);
        recips[1] = address(0x777);
        uint256 quant = 1;
        erc1155Press.mintExisting{ value: mintExistingPriceInit * quant}(1, recips, quant);
        require(erc1155Press.balanceOf(address(0x666), 1) == quant, "balanceOf incorrect"); 
    }
    
    function test_editMetadata() public setUpERC1155PressBase setUpExistingMint(1) {        
        vm.startPrank(INITIAL_OWNER);
        ERC1155EditionRenderer(address(erc1155Press.getRenderer(1))).setTokenURI(
            address(erc1155Press),
            1,
            "new_string"
        );
        require(keccak256(bytes(erc1155Press.uri(1))) == keccak256(bytes("new_string")), "metadata update didnt work");
        vm.stopPrank();
        vm.startPrank(RANDOM_WALLET);
        // non permissioned user has no access to edit uri
        //      editionRenderer is targeted directly here to test the expectRevert
        vm.expectRevert();
        editionRenderer.setTokenURI(
            address(erc1155Press),
            1,
            "malicious_string"
        );        
    }    

    function test_updateConfig() public setUpERC1155PressBase setUpExistingMint(1) {        
        vm.startPrank(INITIAL_OWNER);
        uint256 tokenToCheck = 1;
        ERC1155EditionTokenLogic tokenLogic2 = new ERC1155EditionTokenLogic();
        ERC1155EditionRenderer editionRenderer2 = new ERC1155EditionRenderer();
        erc1155Press.setConfig(
            tokenToCheck, 
            payable(address(0x777)), 
            1_00, 
            tokenLogic2, 
            tokenLogicInit, 
            editionRenderer2, 
            tokenRendererInit
        );
        require(erc1155Press.getFundsRecipient(tokenToCheck) == payable(address(0x777)), "config updated incorrectly");
        require(erc1155Press.getTokenLogic(tokenToCheck) == tokenLogic2, "config updated incorrectly");
        require(erc1155Press.getRenderer(tokenToCheck) == editionRenderer2, "config updated incorrectly");
    }   

    function test_withdraw() public setUpERC1155PressBase setUpExistingMint(1) {     
        // custom set up to add a second different funds recipient for bath withdraw testing
        vm.startPrank(INITIAL_OWNER);
        address[] memory mintNewRecipients = new address[](2);
        mintNewRecipients[0] = ADMIN;
        mintNewRecipients[1] = MINTER;
        uint256 quantity = 1;
        address payable fundsRecipient = payable(address(0x333));
        uint16 royaltyBPS = 10_00; // 10%
        address payable primarySaleFeeRecipient = payable(address(0x222));
        uint16 primarySaleFeeBPS = 5_00; // 5%
        bool soulbound = false;
            erc1155Press.mintNew{
                value: erc1155Press.contractLogic().mintNewPrice(
                    address(erc1155Press),
                    INITIAL_OWNER,
                    mintNewRecipients,
                    quantity
                )
            }(
                mintNewRecipients,
                quantity,
                tokenLogic,
                tokenLogicInit,
                editionRenderer,
                tokenRendererInit,
                fundsRecipient,
                royaltyBPS,
                primarySaleFeeRecipient,
                primarySaleFeeBPS,
                soulbound
            );        
        // end custom setup
        vm.deal(address(erc1155Press), 2 ether);
        uint256[] memory tokensToCheck = new uint256[](2);
        tokensToCheck[0] = 1;           
        tokensToCheck[1] = 2;           
        uint256 contractBalanceBefore = address(erc1155Press).balance;
        uint256 token1_funds_before = erc1155Press.tokenFundsInfo(tokensToCheck[0]);
        // (address payable feeRecip1, uint16 bps1) = erc1155Press.getPrimarySaleFeeDetails(tokensToCheck[0]);
        // uint256 token1_fees = token1_funds_before * bps1 / 10_000;        
        address fundsRecip1 = erc1155Press.getFundsRecipient(tokensToCheck[0]);        
        uint256 token2_funds_before = erc1155Press.tokenFundsInfo(tokensToCheck[1]);
        // (address payable feeRecip2, uint16 bps2) = erc1155Press.getPrimarySaleFeeDetails(tokensToCheck[1]);        
        // uint256 token2_fees = token2_funds_before * bps2 / 10_000; 
        address fundsRecip2 = erc1155Press.getFundsRecipient(tokensToCheck[1]);

        erc1155Press.withdraw(tokensToCheck);        
        
        // require(fundsRecip1.balance == (token1_funds_before - token1_fees), "math not good");
        // require(feeRecip1.balance == (token1_fees), "math not good");
        // require(fundsRecip2.balance == (token2_funds_before - token2_fees), "math not good");
        // require(feeRecip2.balance == (token2_fees), "math not good"); 
        require(address(erc1155Press).balance == contractBalanceBefore - (token1_funds_before + token2_funds_before), "math not good");       
    }       

    function test_burn() public setUpERC1155PressBase setUpExistingMint(1) {   
        vm.startPrank(INITIAL_OWNER);
        // INITIAL OWNER DOESNT HAVE ANY COPIES OF TOKEN #1 SO CANT BURN
        vm.expectRevert();
        erc1155Press.burn(1, 1);
        vm.stopPrank();
        vm.startPrank(ADMIN);
        uint256 balanceBeforeBurn = erc1155Press.balanceOf(ADMIN, 1);
        // ex[ect revert because burning more than balance]
        vm.expectRevert();
        erc1155Press.burn(1, (balanceBeforeBurn + 1));
        // reset
        uint256 amountToBurn = 1;
        erc1155Press.burn(1, amountToBurn);
        require(erc1155Press.balanceOf(ADMIN, 1) == (balanceBeforeBurn - amountToBurn), "burn didnt work");
    }

    function test_soulbound() public setUpERC1155PressBase {
        vm.startPrank(INITIAL_OWNER);
        vm.deal(INITIAL_OWNER, 10 ether);
        address[] memory mintNewRecipients = new address[](2);
        mintNewRecipients[0] = INITIAL_OWNER;
        mintNewRecipients[1] = MINTER;
        uint256 quantity = 1;
        address payable fundsRecipient = payable(ADMIN);
        uint16 royaltyBPS = 10_00; // 10%
        address payable primarySaleFeeRecipient = payable(MINTER);
        uint16 primarySaleFeeBPS = 5_00; // 5%
        // SET TOKENS SOULBOUND
        bool soulboundTrue = true;        
        bool soulboundFalse = false;        
        erc1155Press.mintNew{
            value: erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            )
        }(
            mintNewRecipients,
            quantity,
            tokenLogic,
            tokenLogicInit,
            editionRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulboundTrue
        );        
        require(erc1155Press.isSoulbound(1) == true, "soulbound didnt work");
        bytes memory emptyData = new bytes(0);
        // transaction should revert because token is soulbound
        vm.expectRevert();
        erc1155Press.safeTransferFrom(INITIAL_OWNER, ADMIN, 1, 1, emptyData);
        // check that user can still burn even if they cant transfer token
        erc1155Press.burn(1, 1);        
        // testing that non soulbound tokens CAN be transferred
        erc1155Press.mintNew{
            value: erc1155Press.contractLogic().mintNewPrice(
                address(erc1155Press),
                INITIAL_OWNER,
                mintNewRecipients,
                quantity
            )
        }(
            mintNewRecipients,
            quantity,
            tokenLogic,
            tokenLogicInit,
            editionRenderer,
            tokenRendererInit,
            fundsRecipient,
            royaltyBPS,
            primarySaleFeeRecipient,
            primarySaleFeeBPS,
            soulboundFalse
        );            
        require(erc1155Press.isSoulbound(2) == false, "soulbound didnt work");       
        // transfer should go through because not soulbound
        erc1155Press.safeTransferFrom(INITIAL_OWNER, ADMIN, 2, 1, emptyData); 
    }

    // batchMintExisting --> multi token checkout flow
    // function test_batchMintExisting() public setUpERC1155PressBase setUpExistingMint(2) {        
    //     vm.startPrank(INITIAL_OWNER);
    //     vm.deal(INITIAL_OWNER, 10 ether);
    //     uint256[] memory quants = new uint256[](2);
    //     quants[0] = 100;
    //     quants[1] = 50;
    //     uint256[] memory tokenIds = new uint256[](2);
    //     tokenIds[0] = 1;
    //     tokenIds[1] = 2;
    //     address recipient = address(0x666);
    //     erc1155Press.batchMintExisting{ value: mintExistingPriceInit * (quants[0] + quants[1])}(tokenIds, recipient, quants);
    //     require(erc1155Press.balanceOf(recipient, 1) == quants[0], "balanceOf incorrect");
    //     require(erc1155Press.balanceOf(recipient, 2) == quants[1], "balanceOf incorrect");
    // }    

    function test_batchBurn() public setUpERC1155PressBase setUpExistingMint(2) {   
        vm.startPrank(INITIAL_OWNER);
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;        
        // INITIAL OWNER DOESNT HAVE ANY COPIES OF TOKEN #1 SO CANT BURN
        vm.expectRevert();
        erc1155Press.batchBurn(tokenIds, amounts);
        vm.stopPrank();
        vm.startPrank(ADMIN);
        uint256 balanceBeforeBurn = erc1155Press.balanceOf(ADMIN, 1);
        // ex[ect revert because burning more than balance]
        amounts[0] ++;
        amounts[1] ++;           
        vm.expectRevert();
        erc1155Press.batchBurn(tokenIds, amounts);
        // reset
        amounts[0] --;
        amounts[1] --;
        erc1155Press.batchBurn(tokenIds, amounts);
        require(erc1155Press.balanceOf(ADMIN, tokenIds[0]) == (balanceBeforeBurn - amounts[0]), "burn didnt work");
        require(erc1155Press.balanceOf(ADMIN, tokenIds[1]) == (balanceBeforeBurn - amounts[1]), "burn didnt work");
    }    

    function test_factory() public {
        vm.startPrank(INITIAL_OWNER);

        erc1155Creator = new ERC1155PressFactory(erc1155PressImpl);        

        infiniteEditions = ERC1155Press(payable(erc1155Creator.createPress(
            "Infinte Editions", // name
            "IE", // symbol
            INITIAL_OWNER, // initial owner
            contractLogic, // contract level logic
            altContractLogicInit // contract level logic init
        )));

        address[] memory mintNewRecipients = new address[](1);
        mintNewRecipients[0] = INITIAL_OWNER;
        bytes memory infiniteEditionLogicIinit = abi.encode(
            INITIAL_OWNER, // initial token admin address
            0, // edition start time
            0 // mintPrice
        );
        string memory tokenURI = "https://studio.api.manifoldxyz.dev/asset_uploader/1/asset/3607672823/metadata/full";
        bytes memory editionRendererInit = abi.encode(tokenURI);


        infiniteEditions.mintNew(
            mintNewRecipients, // recipients
            1, // quantity 
            tokenLogic, // token level logic
            infiniteEditionLogicIinit, // token logic init
            editionRenderer, // token level renderer 
            editionRendererInit, // token level renderer init
            payable(INITIAL_OWNER), // funds recipient
            0, // royaltyBPS
            payable(address(0)), // primarySaleFeeRecipient
            0, // primarySaleFeeBPS
            false // soulbound
        );
        vm.stopPrank();
        // need to change addresses since the mintCapPerAddress limit
        // on infinite editions for free mints is 1
        vm.startPrank(address(0x1243));

        address[] memory mintExistingRecipients = new address[](1);
        mintExistingRecipients[0] = address(0x1243);
        infiniteEditions.mintExisting(
            1, // tokenId
            mintExistingRecipients, // mint recipients
            1 // quantity
        );

        require(infiniteEditions.balanceOf(address(0x1243), 1) == 1, "balanceOf incorrect");
        require(keccak256(bytes(infiniteEditions.uri(1))) == keccak256(bytes(tokenURI)), "uri is wrong");    
    }
}