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

interface IERC721PressDatabase {
    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /**
     * @notice Data structure used to store Press settings in database
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: storedCounter (32) = 32 bytes
     * Second slot: logic (20) + initialized (1) = 21 bytes
     * Third slot: renderer (20) = 20 bytes
     */
    struct Settings {
        /// @notice Keeps track of how many data slots have been filled
        uint256 storedCounter;
        /// @notice Address of the logic contract
        address logic;
        /// @notice initialized uint. 0 = not initialized, 1 = initialized
        uint8 initialized;
        /// @notice Address of the renderer contract
        address renderer;
    }

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    /// @notice New factory has been given access to Database
    event NewFactoryAdded(address indexed sender, address indexed factory);

    /// @notice Emitted when new Press is initialized in database by official factory
    event PressInitialized(address indexed sender, address indexed targetPress);

    /// @notice Logic has been updated
    event LogicUpdated(address indexed targetPress, address indexed logic);

    /// @notice Renderer has been updated
    event RendererUpdated(address indexed targetPress, address indexed renderer);

    /// @notice Data has been stored
    event DataStored(
        address indexed targetPress, address indexed storeCaller, uint256 indexed tokenId, address pointer
    );

    /// @notice Data has been overwritten
    event DataOverwritten(
        address indexed targetPress, address indexed overwriteCaller, uint256 indexed tokenId, address newPointer
    );

    /// @notice Data has been removed
    event DataRemoved(address indexed targetPress, address indexed removeCaller, uint256 indexed tokenId);

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // INVALID + FAILURE ERRORS
    //////////////////////////////

    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice TokenId has not been minted
    error Token_Not_Minted();

    //////////////////////////////
    // ACCESS ERRORS
    //////////////////////////////

    /// @notice msg.sender does not have access to initialize a given Press
    error No_Initialize_Access();
    /// @notice msg.sender does not have access to adjust Settings for given Press
    error No_Settings_Access();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Sets official factory for database
    function setOfficialFactory(address factory) external;
    /// @notice Ininitializes Press in database
    function initializePress(address targetPress, bytes memory optionalPressInit) external;
    /// @notice Initializes database with arbitrary data
    function initializeWithData(bytes memory initData) external;
    /// @notice Stores aribtrary data in database
    function storeData(address storeCaller, bytes calldata data) external;
    /// @notice Overwrite data stored in database for a given token
    function overwriteData(address overwriteCaller, uint256[] calldata tokenIds, bytes[] calldata newData) external;
    /// @notice Flag to database that token has been burned
    function removeData(address removeCaller, uint256[] calldata tokenIds) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    /// @notice Returns contractURI for a given Press
    function contractURI() external view returns (string memory);
    /// @notice Returns tokenURI for a given Press + tokenId
    function tokenURI(uint256 tokenId) external view returns (string memory);
    /// @notice Getter for data of a specific id of a given Press
    function readData(address targetPress, uint256 id) external view returns (bytes memory);
    /// @notice Getter for all active data of a given Press
    function readAllData(address targetPress) external view returns (bytes[] memory);
    /// @notice Calculates total data storage fee based on targetPress, mintCaller, and number of tokens
    function getStorageFee(address targetPress, address user, uint256 numTokens)
        external
        view
        returns (address, uint256);
    /// @notice Checks if a certain address can access mint functionality for a given Press + quantity combination
    function canMint(address targetPress, address mintCaller, uint256 mintQuantity) external view returns (bool);
    /// @notice Checks if a certain address can call the burn function for a given Press
    function canBurn(address targetPress, address burnCaller, uint256 tokenId) external view returns (bool);
    /// @notice Checks if a certain address can update the settings {logic, renderer} for a given Press
    function canEditSettings(address targetPress, address settingsCaller) external view returns (bool);
    /// @notice Checks if a certain address can edit contract data post data storage for a given Press
    function canEditContractData(address targetPress, address metadataCaller) external view returns (bool);
    /// @notice Checks if a certain address can edit token data post data storage for a given Press
    function canEditTokenData(address targetPress, address metadataCaller, uint256 tokenId)
        external
        view
        returns (bool);
    /// @notice Checks if a certain address can edit payments related information for a givenPress
    function canEditPayments(address targetPress, address withdrawCaller) external view returns (bool);
}
