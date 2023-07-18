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

interface IAP721Database {  

    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /**
     * @notice Data structure used to store AP721 config in database
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: fundsRecipient (20) + royaltyBPS (2) + transferable (1) = 23 bytes
     */
    struct AP721Config {
        /// @notice 
        address fundsRecipient;
        /// @notice 
        uint16 royaltyBPS;
        /// @notice 
        bool transferable;
    }

    /**
     * @notice Data structure used to store Press settings in database
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: storageCounter (32) = 32 bytes
     * Second slot: logic (20) + initialized (1) = 21 bytes
     * Third slot: renderer (20) = 20 bytes   
     * TODO: confirm that the struct takes up all 32 bytes even if the storage inside of it is less than 32
     * Fourth slot: ap721Config (32) = 32 bytes
     */
    struct Settings {
        /// @notice Keeps track of how many data slots have been filled
        uint256 storageCounter;                
        /// @notice Address of the logic contract
        address logic;                        
        /// @notice initialized uint. 0 = not initialized, 1 = initialized
        uint8 initialized;
        /// @notice Address of the renderer contract
        address renderer;   
        /// Stores config settings for AP721 contract
        AP721Config ap721Config;
    }    

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
    event SetupAP721 (
        address indexed ap721,
        address indexed sender,
        address indexed initialOwner,
        address logic,
        address renderer,
        address factory 
    );

    /// @notice Logic has been updated
    event LogicUpdated(
        address indexed target,
        address indexed logic
    );    

    /// @notice Renderer has been updated
    event RendererUpdated(
        address indexed target,
        address indexed renderer
    );  


    /// @notice Data has been stored
    event DataStored(
        address indexed target,
        address indexed sender,
        uint256 indexed tokenId,
        address pointer
    );             

    /// @notice Data has been overwritten
    event DataOverwritten(
        address indexed target,
        address indexed sender,
        uint256 indexed tokenId,
        address pointer
    );           

    /// @notice Data has been removed
    event DataRemoved(
        address indexed target,
        address indexed sender,
        uint256 indexed tokenId
    );          

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // INVALID + FAILURE ERRORS
    //////////////////////////////     

    /// @notice Target has not been initialized
    error Target_Not_Initialized(); 
    /// @notice TokenId has not been minted
    error Token_Not_Minted();    
    /// @notice Array input lengths don't match
    error Invalid_Input_Length();     

    //////////////////////////////
    // ACCESS ERRORS
    //////////////////////////////  
    
    /// @notice Msg.sender does not have access to call store for tatget
    error No_Store_Access();    
    /// @notice Msg.sender does not have access to call overwrite for tatget
    error No_Overwrite_Access();                
    /// @notice Msg.sender does not have access to call remove for tatget
    error No_Remove_Access();    
    /// @notice Msg.sender does not have access to edit settings for tatget
    error No_Settings_Access();        

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////           

    /// @notice Facilitates deploy + initialization of a new, creator-owned proxy of `AP721.sol`
    function setupAP721(
        address initialOwner,
        bytes memory databaseInit,
        address factory,
        bytes memory factoryInit
    ) external returns (address);
    /// @notice Store aribtrary data in database
    function store(address target, uint256 quantity, bytes memory data) external;
    /// @notice Overwrite data stored in database for a given token
    function overwrite(address target, uint256[] memory tokenIds, bytes[] memory data) external;
    /// @notice Erase data stored in database for a given token
    function remove(address target, uint256[] memory tokenIds) external;

    // /// @notice Facilitates deploy + initialization of multiple, creator-owned proxies of `AP721.sol`
    // function multiSetupAP721(
    //     address[] memory initialOwners,
    //     bytes[] memory databaseInits,
    //     address[] memory factories,
    //     bytes[] memory factoryInits
    // ) external returns (address[] memory);    
    // /// @notice Store aribtrary data in database for multiple targets
    // function multiStore(address[] memory targets, bytes[] memory data) external;
    // /// @notice Overwrite data stored in database for a given token for multiple targets
    // function multiOverwrite(address[] memory targets, uint256[][] memory tokenIds, uint256[][] memory data) external;
    // /// @notice Erase data stored in database for a given token for multiple targets
    // function multiErase(address[] memory targets, uint256[][] memory tokenIds) external;  

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
    function getTransferable(address target) external view returns (bool);
}