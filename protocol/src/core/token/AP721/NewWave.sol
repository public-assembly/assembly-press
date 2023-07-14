// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/* PA */

/**
 */
contract NewWave {


    // call to Database
    function setupPress(
        address initialOwner, 
        bytes memory databaseInit,
        address factory,
        bytes memory factoryInit
    ) external {
        address ap721 = IAP721Factory(factory).create(
            initialOwner,
            factoryInit
        );
        pressSettings[ap721].initialized = 1;
        // Data format: logic, logicInit, renderer, rendererInit, feeModule
        (
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit,
            address feeModule
        ) = abi.decode(databaseInit, (address, bytes, address, bytes, address));
        _setLogic(ap721, logic, logicInit);
        _setRenderer(ap721, renderer, rendererInit);
        _setFeeModule(ap721);
    }

    // call to Factory
    function createPress(
        address initialOwner, 
        bytes memory factoryInit,
        address database
    ) external {
        ERC721PressProxy newPress = new ERC721PressProxy(pressImpl, "");
        (
            string memory name,
            string memory symbol,
            Settings memory settings
        ) = abi.decode(factoryIinit, (string, string, Settings));
        ERC721Press(payable(address(newPress))).initialize({
            name: name,
            symbol: symbol,
            initialOwner: initialOwner,
            settings: settings,
            database: database
        });
    }

    // call to Press
    function initialize(
        address initialOwner, 
        bytes memory factoryInit
    ) external {

        // Initialize ERC721A
        __ERC721A_init(name, symbol);
        // Initialize reentrancy guard
        __ReentrancyGuard_init();
        // Initialize owner for Ownable
        __Ownable_init(initialOwner);
        // Initialize UUPS
        __UUPSUpgradeable_init();                     
        // Set + Initialize Database
        _database = database;   
        // Check royaltyBPS for acceptable value
        if (settings.royaltyBPS > MAX_ROYALTY_BPS) {
            revert Royalty_Percentage_Too_High(MAX_ROYALTY_BPS);
        }
        // Initialize settings: {fundsRecipient, royaltyBPS, token transferability}
        _settings = settings;   
    }

    // call to Database
    function store(
        address targetPress, 
        uint256 quantity,
        bytes memory data
    ) external {

        // Cache msg.sender 
        address sender = _msgSender();
        // Cache msg.value
        uint256 msgValue = msg.value;


        if (pressSettings[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }
        if (IAP721Logic(pressSettings[targetPress].logic).canStore(targetPress, sender, quantity) == false) {
            revert No_Store_Access();
        }
        if (msgValue != getStorageFee(targetPress, sender, quantity)) {
            revert Incorrect_Msg_Value();
        }

        // Calculate number of tokens
        bytes[] memory tokens = abi.decode(data, (bytes[]));

        // Store data for each token
        for (uint256 i = 0; i < tokens.length; ++i) {
            // Check data is valid
            _validateData(tokens[i]);
            // Cache storedCounter
            // NOTE: storedCounter trails associated tokenId by 1
            uint256 storedCounter = pressSettings[targetPress].storedCounter;
            // Use sstore2 to store bytes segments from bytes array                
            idToData[targetPress][storedCounter] = SSTORE2.write(
                tokens[i]
            );       
            emit DataStored(
                sender, 
                storeCaller,
                storedCounter + 1,  
                idToData[sender][storedCounter]
            );                                       
            // increment press storedCounter after storing data
            ++settingsInfo[sender].storedCounter;              
        }       

        // Mint tokens to sender
        IAP721(targetPress).mint(quantity, sender);
    }   

    // call to Press
    function mint(uint256 quantity, address recipient) external {    
        if (msg.sender != databaseImpl) {
            revert Unauthorized_Mint_Access();
        }
        _mintNFTs(quantity, recipient);
    }
}