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

interface IERC1155PressDatabase {
    ////////////////////////////////////////////////////////////
    // TYPES
    ////////////////////////////////////////////////////////////

    /**
     * @notice Data structure used to store contract settings in database for a given Press
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: storedCounter (32) = 32 bytes
     * Second slot: logic (20) = 20 bytes
     * Third slot: renderer (20) + initialized (1) = 21 bytes
     */
    struct PressSettings {
        /// @notice Keeps track of how many data slots have been filled
        uint256 storedCounter;
        /// @notice Address of the logic contract
        address logic;
        /// @notice Address of the renderer contract
        address renderer;
        /// @notice Has contract been initialized. 0 = not initialized, 1 = initialized
        uint8 initialized;
    }

    /**
     * @notice Data structure used to store token settings in database for a given token + Press
     * @dev Struct breakdown. Values in parentheses are bytes.
     *
     * First slot: fuudsRecipient (20) + royaltyBPS (2) + transferable (1) + initialized (1) = 24 bytes
     * Second slot: tokenLogic (20) = 20 bytes
     * Third slot: tokenRenderer (20) = 20 bytes
     */
    struct TokenSettings {
        /// @notice Address that receives funds from sale
        address payable fundsRecipient;
        /// @notice BPS of the royalty set on the contract. Can be 0 for no royalty
        uint16 royaltyBPS;
        /// @notice Whether or not tokens from this contract can be transferred
        bool transferable;
        /// @notice Has token been initialized. 0 = not initialized, 1 = initialized
        uint8 initialized;
        /// @notice Address of the logic contract
        address logic;
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

    /// @notice Press logic has been updated
    event PressLogicUpdated(address indexed targetPress, address indexed logic);

    /// @notice Press renderer has been updated
    event PressRendererUpdated(address indexed targetPress, address indexed renderer);

    /// @notice Press logic has been updated
    event TokenLogicUpdated(address indexed targetPress, uint256 indexed tokenId, address indexed logic);

    /// @notice Token renderer has been updated
    event TokenRendererUpdated(address indexed targetPress, uint256 indexed tokenId, address indexed renderer);

    /// @notice Data has been stored
    event DataStored(
        address indexed targetPress, address indexed storeCaller, uint256 indexed tokenId, address pointer
    );

    /// @notice Data has been overwritten
    event DataOverwritten(
        address indexed targetPress, address indexed overwriteCaller, uint256 indexed tokenId, address newPointer
    );

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // INVALID + FAILURE ERRORS
    //////////////////////////////

    /// @notice Target Press has not been initialized
    error Press_Not_Initialized();
    /// @notice Target Press => tokenId has not been initialized
    error Token_Not_Initialized();
    /// @notice TokenId has not been minted
    error Token_Not_Minted();

    //////////////////////////////
    // ACCESS ERRORS
    //////////////////////////////

    /// @notice msg.sender does not have access to initialize a given Press or token
    error No_Initialize_Access();
    /// @notice msg.sender does not have access to adjust PressSettings for given Press
    error No_PressSettings_Access();
    /// @notice msg.sender does not have access to adjust tokenSettings for given Press
    error No_TokenSettings_Access();

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Initializes database with arbitrary data
    function initializePressWithData(bytes memory initData) external;
    /// @notice Checks if a certain address can edit contract data post data storage for a given Press
    function canEditContractData(address targetPress, address metadataCaller) external view returns (bool);
}
