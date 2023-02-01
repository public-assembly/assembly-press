// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {console2} from "forge-std/console2.sol";

import {ERC1155PressConfig} from "./utils/ERC1155PressConfig.sol";
import {ERC1155BasicContractLogic} from "../../src/token/ERC1155/logic/ERC1155BasicContractLogic.sol";
import {ERC1155Press} from "../../src/token/ERC1155/ERC1155Press.sol";

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
        uint16 accessRole = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),contractAdminInit);
        (uint256 mintNewPrice, uint8 initialized) = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).contractInfo(address(erc1155Press));
        require(accessRole == 2, "admin role was set wrong");
        require(mintNewPrice == 0.01 ether, "mintprice is wrong");
        require(initialized == 1, "initialized is wrong");
        require(erc1155Press.contractLogic().isInitialized(address(erc1155Press)) == true, "isInitialized incorrect");                  

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
            ) == (mintNewPrice * mintQuantity), "mintNewPrice incorrect:"
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

        // canUpgrade                
        require(
            erc1155Press.contractLogic().canUpgrade(
                address(erc1155Press),
                RANDOM_WALLET
            ) == false, "canUpgrade roles incorrect"
        );          
        require(
            erc1155Press.contractLogic().canUpgrade(
                address(erc1155Press),
                INITIAL_OWNER
            ) == true, "canUpgrade roles incorrect"
        );   
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
        ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).setAccessControl(
            address(erc1155Press),
            receivers,
            roles
        );
        // check to make sure addresses have correct roles
        uint16 accessRole1 = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),ADMIN);
        uint16 accessRole2 = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),MINTER);
        uint16 accessRole3 = ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).accessInfo(address(erc1155Press),RANDOM_WALLET);
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
            basicRenderer,
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
            basicRenderer,
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
        ERC1155BasicContractLogic(address(erc1155Press.contractLogic())).setAccessControl(
            address(erc1155Press),
            receivers,
            roles
        );
        vm.stopPrank();
        vm.startPrank(ADMIN);
        erc1155Press.upgradeTo(erc1155PressImpl3);
    }    


    // mintNew token logic set up confirmation
    // mintNew token renderer set up
    // mintExisting -- gas snapshot
    // batchMintExisting -- gas snapshot
    // burn
    // batchburn
    // withdraw -- gas snapshot
    // batchWithdraw -- gas snapshot
    // soulbound related tests
    //      cant transfer tokens
    //      can still burn tokens even if soulbound
}