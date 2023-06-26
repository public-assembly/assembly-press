// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721PressDatabase {  

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice Shared struct used to store data for a given token
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * pointer (20) + sortOrder (12) = 32 bytes
    */
    struct TokenData {
        /// @notice Sstore2 data pointer        
        address pointer;
        /// @notice Optional z-index style sorting mechanism for ids. Can be negative
        int96 sortOrder;
    }

    /// @notice Shared struct used to store data for a given token
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * pointer (20) + sortOrder (12) = 32 bytes
    */
    struct TokenDataRetrieved {
        /// @notice Bytes data stored atsstore2 data pointer        
        bytes storedData;
        /// @notice Optional z-index style sorting mechanism for ids. Can be negative
        int96 sortOrder;
    }    

    /// @notice Shared struct tracking Press settings in database
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * storedCounter (32) = 32 bytes
     * Second slot     
     * logic (20) + initialized (1) = 21 bytes
     * Third slot
     * renderer (20) = 20 bytes   
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

    // ||||||||||||||||||||||||||||||||
    // ||| FUNCTIONS ||||||||||||||||||
    // ||||||||||||||||||||||||||||||||
    
    // Write functions
    /// @notice Ininitializes Press in database
    function initializePress(address targetPress) external;        
    /// @notice initializes database with arbitrary data
    function initializeWithData(bytes memory initData) external;    
    /// @notice stores aribtrary data in database
    function storeData(bytes calldata data) external;
    /// @notice sorts data stored in database
    function sortData(address targetPress, uint256[] calldata tokenIds, int96[] calldata sortOrders) external;    
    /// @notice updated data stored in database for a given token
    function updateData(uint256[] calldata tokenIds, bytes[] calldata newData) external;    
    /// @notice flag to database that token has been burned
    function removeData(uint256[] calldata tokenIds) external;        

    // Read Functions
    /// @notice returns contractURI for a given Press    
    function contractURI() external view returns (string memory);    
    /// @notice returns tokenURI for a given Press + tokenId
    function tokenURI(uint256 tokenId ) external view returns (string memory);                
    /// @notice Getter for data of a specific id of a given Press
    function readData(address targetPress, uint256 id) external view returns (TokenDataRetrieved memory);
    /// @notice calculates total mintPrice based on targetPress, mintCaller, and mintQuantity
    function totalMintPrice(address targetPress, address mintCaller, uint256 mintQuantity) external view returns (uint256);    
    /// @notice checks if a certain address can access mint functionality for a given Press + quantity combination
    function canMint(address targetPress, address mintCaller, uint256 mintQuantity) external view returns (bool);
    /// @notice checks if a certain address can call the burn function for a given Press
    function canBurn(address targetPress, address burnCaller, uint256 tokenId) external view returns (bool);
    /// @notice checks if a certain address can call the sort function for a given Press
    function canSort(address targetPress, address sortCaller) external view returns (bool);    
    /// @notice checks if a certain address can update the settings {logic, renderer} for a given Press 
    function canEditSettings(address targetPress, address settingsCaller) external view returns (bool);           
    /// @notice checks if a certain address can edit contract data post data storage for a given Press
    function canEditContractData(address targetPress, address metadataCaller) external view returns (bool);        
    /// @notice checks if a certain address can edit token data post data storage for a given Press
    function canEditTokenData(address targetPress, address metadataCaller, uint256 tokenId) external view returns (bool);    
    /// @notice checks if a certain address can edit payments related information for a givenPress
    function canEditPayments(address targetPress, address withdrawCaller) external view returns (bool);  
    
    // ||||||||||||||||||||||||||||||||
    // ||| EVENTS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice New factory has been given access to Database
    event NewFactoryAdded(
        address indexed sender,
        address indexed factory
    );        

    /// @notice Emitted when new Press is initialized in database by official factory
    event PressInitialized(
        address indexed sender,
        address indexed targetPress
    );

    /// @notice Logic has been updated
    event LogicUpdated(
        address indexed targetPress,
        address indexed logic
    );    

    /// @notice Renderer has been updated
    event RendererUpdated(
        address indexed targetPress,
        address indexed renderer
    );    

    /// @notice Data has been stored
    event DataStored(
        address indexed targetPress,
        uint256 indexed tokenId,
        address pointer
    );       

    /// @notice Data has been sorted
    event DataSorted(
        address indexed targetPress,
        uint256[] ids,
        int96[] sortOrder,
        address sortedBy
    );        

    /// @notice Data has been updated
    event DataUpdated(
        address indexed targetPress,
        uint256 indexed tokenId,
        address newPointer
    );           

    /// @notice Data has been removed
    event DataRemoved(
        address indexed targetPress,
        uint256 indexed tokenId
    );          

    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    // Access errors
    /// @notice msg.sender does not have access to initialize a given Press    
    error No_Initialize_Access();
    /// @notice msg.sender does not have access to adjust Settings for given Press
    error No_Settings_Access();    

    // Constraint/invalid/failure errors
    /// @notice Target Press has not been initialized
    error Press_Not_Initialized(); 
}