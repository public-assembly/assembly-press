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

import {IAP721DatabaseTypesV1} from "./IAP721DatabaseTypesV1.sol";

interface IAP721Database is IAP721DatabaseTypesV1 {

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    /// @notice Event emitted when setting up a new AP721
    /// @param ap721 Address of new ap721 setup
    /// @param sender Address of sender who called setupAP721 function
    /// @param initialOwner Address of owner set on AP721
    /// @param logic Address of logic contract set for AP721
    /// @param renderer Address of renderer contract set on ap721
    /// @param factory Address of factory designated for setup process
    event SetupAP721(
        address indexed ap721,
        address indexed sender,
        address indexed initialOwner,
        address logic,
        address renderer,
        address factory
    );
    
    /// @notice Logic has been updated
    event LogicUpdated(address indexed target, address indexed logic);
    /// @notice Renderer has been updated
    event RendererUpdated(address indexed target, address indexed renderer);
    /// @notice Data has been stored
    event DataStored(address indexed target, address indexed sender, uint256 indexed tokenId, address pointer);
    /// @notice Data has been overwritten
    event DataOverwritten(address indexed target, address indexed sender, uint256 indexed tokenId, address pointer);
    /// @notice Data has been removed
    event DataRemoved(address indexed target, address indexed sender, uint256 indexed tokenId);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // INVALID + FAILURE ERRORS
    //////////////////////////////

    /// @notice Target has not been initialized
    error Target_Not_Initialized();
    /// @notice TokenId does not exist
    error Token_Does_Not_Exist();
    /// @notice Array input lengths don't match
    error Invalid_Input_Length();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////
    /// @notice Facilitates deploy + initialization of a new, creator-owned proxy of `AP721.sol`
    function setupAP721(address initialOwner, bytes memory databaseInit, address factory, bytes memory factoryInit) external returns (address);
    /// @notice Store aribtrary data in database
    function store(address target, bytes memory data) external;
    /// @notice Overwrite data stored in database for a given token
    function overwrite(address target, uint256[] memory tokenIds, bytes[] memory data) external;
    /// @notice Erase data stored in database for a given token
    function remove(address target, uint256[] memory tokenIds) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////
    /// @notice Returns contractURI for a given AP721
    function contractURI() external view returns (string memory);
    /// @notice Returns tokenURI for a given AP721 + tokenId
    function tokenURI(uint256 tokenId) external view returns (string memory);
    /// @notice Get token transferability status for a target AP721
    function getSettings(address target) external view returns (Settings memory);
    /// @notice Get token transferability status for a target AP721
    function getTransferability(address target) external view returns (bool);
    /// @notice Checks value of initialized variable in ap721Settings mapping for target
    function isInitialized(address target) external view returns (bool);    
}
