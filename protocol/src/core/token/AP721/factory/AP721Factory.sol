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

import {AP721} from "../nft/AP721.sol";
import {AP721Proxy} from "../nft/proxy/AP721Proxy.sol";
import {IAP721Factory} from "../interfaces/IAP721Factory.sol";
import {Version} from "../../../utils/Version.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

/**
 * @title AP721Factory
 * @notice A factory contract that deploys an AP721Proxy, a UUPS proxy of `AP721.sol`
 *
 * @author Max Bochman
 * @author Salief Lewis
 */
contract AP721Factory is IAP721Factory, Version(1), ReentrancyGuard {
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    /**
     * @notice Implementation contract behind ap721 proxies
     */
    address public immutable ap721Impl;

    /**
     * @notice Enshrined database contract passed into each `create` call
     */
    address public immutable databaseImpl;

    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Checks if database is msg.sender
     */
    modifier onlyDatabase() {
        if (msg.sender != databaseImpl) {
            revert Msg_Sender_Not_Database();
        }

        _;
    }

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////

    /**
     * @notice Sets the implementation address upon deployment
     * @dev Implementation addresses cannot be updated after deployment
     */
    constructor(address _ap721Impl, address _databaseImpl) {
        if (_ap721Impl == address(0) || _databaseImpl == address(0)) {
            revert Address_Cannot_Be_Zero();
        }

        ap721Impl = _ap721Impl;
        databaseImpl = _databaseImpl;

        emit AP721ImplementationSet(_ap721Impl);
        emit DatabaseImplementationSet(databaseImpl);
    }

    //////////////////////////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////////////////////////

    /**
     * @notice Creates a new, creator-owned proxy of `AP721.sol`
     * @param initialOwner User that owns the contract upon deployment
     * @param factoryInit Init to decode and pass to ap721 `initialize` function
     * @return ap721 Address of newly initialized AP721Proxy
     */
    function create(address initialOwner, bytes memory factoryInit)
        public
        nonReentrant
        onlyDatabase
        returns (address ap721)
    {
        // Configure ownership details in proxy constructor
        AP721Proxy newAP721 = new AP721Proxy(ap721Impl, "");
        // Initialize AP721Proxy
        AP721(payable(address(newAP721))).initialize({
            initialOwner: initialOwner,
            database: databaseImpl,
            init: factoryInit
        });
        return address(newAP721);
    }
}
