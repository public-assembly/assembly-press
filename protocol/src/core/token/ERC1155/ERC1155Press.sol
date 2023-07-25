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

import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "../../utils/ownable/single/OwnableUpgradeable.sol";
import {Version} from "../../utils/Version.sol";

import {IERC1155PressDatabase} from "./interfaces/IERC1155PressDatabase.sol";
import {ERC1155PressStorageV1} from "./storage/ERC1155PressStorageV1.sol";

// TODO: potentially consider moving oover to OZ1155 upgradeable so dont need to impelemennt
//      custom upgradeability. originally was done because there were issues implementing
//      soullbound overrides on OZ impl as opposed to Solmate. if still running into issues
//      checkout manifolds 1155 soulbound impl

/**
 * @title ERC1155Press
 * @notice Highly configurable ERC1155 implementation
 * @dev Functionality is configurable using external renderer + logic contracts at both contract and token level
 * @dev Uses EIP-5633 for optional non-transferrable token implementation
 * @author Max Bochman
 * @author Salief Lewis
 */
contract ERC1155Press is
    ERC1155PressStorageV1,
    Version(1),
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    ////////////////////////////////////////////////////////////
    // INITIALIZER
    ////////////////////////////////////////////////////////////

    /**
     * @notice Initializes a new, creator-owned proxy of ERC1155Press.sol
     * @dev `initializer` for OpenZeppelin's OwnableUpgradeable
     * @param _name Contract name
     * @param _symbol Contract symbol
     * @param initialOwner User that owns the contract upon deployment
     * @param database Database implementation address
     * @param databaseInit Data to initialize database contract with
     */
    function initialize(
        string memory _name,
        string memory _symbol,
        address initialOwner,
        IERC1155PressDatabase database,
        bytes memory databaseInit
    ) external nonReentrant initializer {
        // Setup reentrancy guard
        __ReentrancyGuard_init();
        // Setup owner for Ownable
        __Ownable_init(initialOwner);
        // Setup UUPS
        __UUPSUpgradeable_init();

        // Setup contract name + contract symbol. Cannot be updated after initialization
        name = _name;
        symbol = _symbol;

        // Set + Initialize Database
        _database = database;
        _database.initializePressWithData(databaseInit);
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    // // TODO: reconfigure token settings so that a tokenSettings type can be passed in
    // //    to handle the funds recipient rpyalty bps and transferable variables
    // function mintNew(
    //   address[] memory recipients,
    //   uint256 quantity,
    //   bytes memory databaseInit,
    //   bytes memory data,
    //   address payable fundsRecipient,
    //   uint16 royaltyBPS,
    //   bool transferable
    // ) external payable nonReentrant returns (uint256 tokenMinted) {

    //   // TODO: change to "_msgSender()"
    //   address sender = msg.sender;

    //   uint256 initializedToken = _database.initializeToken(databaseInit);

    //   // Update database with data included in `mintWithData` call
    //   _database.storeData(sender, initializedToken, data);

    //   // For each recipient provided, mint them given quantity of tokenId being newly minted
    //   for (uint256 i = 0; i < recipients.length; ++i) {
    //       // Mint quantity of given tokenId to recipient
    //     _mint(recipients[i], tokenId, quantity, new bytes(0));
    //   }
    //   emit NewTokenMinted({
    //       tokenId: tokenId,
    //       sender: sender,
    //       recipient: recipients
    //       quantity: quantity
    //   });
    // }

    // create an array of length 1
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /// @notice This gets the next token in line to be minted when minting linearly (default behavior) and updates the counter
    function _getAndUpdateNextTokenId() internal returns (uint256) {
        unchecked {
            return _tokenCount++;
        }
    }

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Getter for database contract address used by Press
     * @return databaseAddress Database contract used by Press
     */
    function getDatabase() public view returns (IERC1155PressDatabase databaseAddress) {
        return _database;
    }

    /**
     * @notice Getter for tokenIds created for Press
     * @return numMinted Database contract used by Press
     */
    function getNumMinted() public view returns (uint256 numMinted) {
        return _tokenCount;
    }

    //////////////////////////////
    // INTERNAL
    //////////////////////////////

    /// @dev Can only be called by an admin or the contract owner
    /// @param newImplementation proposed new upgrade implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
