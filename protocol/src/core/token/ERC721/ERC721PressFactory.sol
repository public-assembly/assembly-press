// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.
*/

import {ERC721Press} from "./ERC721Press.sol";
import {ERC721PressProxy} from "./proxy/ERC721PressProxy.sol";
import {IERC721Press} from "./interfaces/IERC721Press.sol";
import {IERC721PressDatabase} from "./interfaces/IERC721PressDatabase.sol";
import {IERC721PressFactory} from "./interfaces/IERC721PressFactory.sol";
import {Version} from "../../utils/Version.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title ERC721PressFactory
 * @notice A factory contract that deploys an ERC721PressProxy, a UUPS proxy of `ERC721Press.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC721PressFactory is IERC721PressFactory, Version(1), ReentrancyGuard {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////   

    /**
    * @notice Implementation contract behind Press proxies
    */
    address public immutable pressImpl;

    /**
    * @notice Enshrined database contract passed into each `createPress` call
    */
    address public immutable databaseImpl;  

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////         
    
    /**
    * @notice Sets the implementation address upon deployment
    * @dev Implementation addresses cannot be updated after deployment 
    */
    constructor(address _pressImpl, address _databaseImpl) {
        if (_pressImpl == address(0) || _databaseImpl == address(0)) { 
            revert Address_Cannot_Be_Zero();
        }

        pressImpl = _pressImpl;
        databaseImpl = _databaseImpl;

        emit PressImplementationSet(pressImpl);
        emit DatabaseImplementationSet(databaseImpl);
    }

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////   

    /**
    * @notice Creates a new, creator-owned proxy of `ERC721Press.sol`
    * @param name Contract name
    * @param symbol Contract symbol
    * @param initialOwner User that owns the contract upon deployment
    * @param databaseInit Data to initialize database contract with
    * @param settings See IERC721Press for details 
    * @param optionalPressInit Additional bytes data that can be passed into initializePress call
    * @return press Address of created Press
    */
    function createPress(
        string calldata name,
        string calldata symbol,
        address initialOwner,
        bytes calldata databaseInit,
        IERC721Press.Settings calldata settings,
        bytes calldata optionalPressInit
    ) nonReentrant public returns (address press) {
        // Configure ownership details in proxy constructor
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");
        // Initialize Press in database
        IERC721PressDatabase(databaseImpl).initializePress(address(newPress), optionalPressInit);
        // Initialize the new Press instance
        ERC721Press(payable(address(newPress))).initialize({
            name: name,
            symbol: symbol,
            initialOwner: initialOwner,
            database: IERC721PressDatabase(databaseImpl),
            databaseInit: databaseInit,
            settings: settings
        });
        // Emit creation event from factory
        emit Create721Press({
            newPress: address(newPress),
            databaseImpl: databaseImpl,
            settings: settings
        });        
        return address(newPress);
    }
}