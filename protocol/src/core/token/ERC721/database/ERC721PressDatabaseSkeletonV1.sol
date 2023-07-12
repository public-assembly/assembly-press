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

import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";
import {IERC721Press} from "../interfaces/IERC721Press.sol";
import {ERC721Press} from "../ERC721Press.sol";

import {IERC721PressLogic} from "../interfaces/IERC721PressLogic.sol";
import {IERC721PressRenderer} from "../interfaces/IERC721PressRenderer.sol";

import {ERC721PressDatabaseStorageV1} from "./storage/ERC721PressDatabaseStorageV1.sol";
import {IERC721PressDatabase} from "../interfaces/IERC721PressDatabase.sol";

import "sstore2/SSTORE2.sol";

/**
 * @title ERC721PressDatabaseSkeletonV1
 * @notice V1 generic database architecture. Strategy specific databases can inherit this to ensure compatibility with Assembly Press framework
 * @dev Contracts that inherit this must implement their own `setOfficialFactory`, `storeData`, `overwriteData` functions
 *       to comply with IERC721PressDatabase interface
 * @author Max Bochman
 * @author Salief Lewis
 */
abstract contract ERC721PressDatabaseSkeletonV1 is
    ERC721PressDatabaseStorageV1,
    IERC721PressDatabase
{
    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Checks if target Press has been initialized to the database
     */
    modifier requireInitialized(address targetPress) {
        if (settingsInfo[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }

        _;
    }

    ////////////////////////////////////////////////////////////
    // WRITE FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // DATABASE ADMIN
    //////////////////////////////

    /**
     * @notice Initializes a Press, giving it the ability to write to database
     * @dev Can only be called by address set as officialFactory
     * @dev Addresses cannot be un-initialized
     * @param targetPress Address of Press to initialize
     */
    function initializePress(address targetPress) external {
        if (_officialFactories[msg.sender] != true) {
            revert No_Initialize_Access();
        }
        settingsInfo[targetPress].initialized = 1;

        emit PressInitialized(msg.sender, targetPress);
    }

    /**
     * @notice Getter for officialFactory status of an address. If true, can call `initializePress`
     * @param target Address to check
     */
    function isOfficialFactory(address target) external view returns (bool) {
        return _officialFactories[target];
    }

    //////////////////////////////
    // PRESS INITIALIZATION
    //////////////////////////////

    /**
     * @notice Default database initializer for a given Press
     * @dev Initializes settings for a given Press
     * @param databaseInit data to init with
     */
    function initializeWithData(
        bytes memory databaseInit
    ) external requireInitialized(msg.sender) {
        // Cache msg.sender
        address sender = msg.sender;

        // Data format: logic, logicInit, renderer, rendererInit
        (
            address logic,
            bytes memory logicInit,
            address renderer,
            bytes memory rendererInit
        ) = abi.decode(databaseInit, (address, bytes, address, bytes));

        // Sets ands initializes logic + renderer contracts
        _setLogic(sender, logic, logicInit);
        _setRenderer(sender, renderer, rendererInit);
    }

    //////////////////////////////
    // PRESS SETTINGS
    //////////////////////////////

    /**
     * @notice Facilitates updating of logic contract for a given Press
     * @dev LogicInit can be blank
     * @param targetPress Press to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function setLogic(
        address targetPress,
        address logic,
        bytes memory logicInit
    ) external requireInitialized(targetPress) {
        // Request settings access from logic contract
        if (
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getSettingsAccess(targetPress, msg.sender) == false
        ) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(targetPress, logic, logicInit);
    }

    /**
     * @notice Facilitates updating of renderer contract for a given Press
     * @dev RendererInit can be blank
     * @param targetPress Press to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function setRenderer(
        address targetPress,
        address renderer,
        bytes memory rendererInit
    ) external requireInitialized(targetPress) {
        // Request settings access from logic contract
        if (
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getSettingsAccess(targetPress, msg.sender) == false
        ) {
            revert No_Settings_Access();
        }
        // Update + initialize new renderer contract
        _setRenderer(targetPress, renderer, rendererInit);
    }

    /**
     * @notice Internal handler for setLogic function
     * @dev No access checks, enforce elsewhere
     * @param targetPress Press to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function _setLogic(
        address targetPress,
        address logic,
        bytes memory logicInit
    ) internal {
        settingsInfo[targetPress].logic = logic;
        IERC721PressLogic(logic).initializeWithData(targetPress, logicInit);

        emit LogicUpdated(targetPress, logic);
    }

    /**
     * @notice Internal handler for setRenderer function
     * @dev RendererInit can be blank
     * @param targetPress Press to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function _setRenderer(
        address targetPress,
        address renderer,
        bytes memory rendererInit
    ) internal {
        settingsInfo[targetPress].renderer = renderer;
        IERC721PressRenderer(renderer).initializeWithData(
            targetPress,
            rendererInit
        );

        emit RendererUpdated(targetPress, renderer);
    }

    //////////////////////////////
    // REMOVE DATA
    //////////////////////////////

    /**
     * @notice Event emitter that signals for indexer that this token has been burned.
     * @dev When a token is burned, the data associated with it will no longer be returned
     *     in `getAllData`, and will return zero values in `getData`
     * @param removeCaller address of account initiating `burn` from targetPress
     * @param tokenIds tokenIds to target
     */
    function removeData(
        address removeCaller,
        uint256[] memory tokenIds
    ) external requireInitialized(msg.sender) {
        for (uint256 i; i < tokenIds.length; ++i) {
            delete idToData[msg.sender][tokenIds[i]-1];
            emit DataRemoved(msg.sender, removeCaller, tokenIds[i]);
        }
    }

    ////////////////////////////////////////////////////////////
    // READ FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // READ DATA
    //////////////////////////////

    /**
     * @notice Getter for acessing data for a specific ID for a given Press
     * @dev Fetches + returns stored bytes values from sstore2
     * @param targetPress ERC721Press to target
     * @param tokenId tokenId to retrieve data for
     * @return data Data stored for given token
     */
    function readData(
        address targetPress,
        uint256 tokenId
    )
        external
        view
        requireInitialized(targetPress)
        returns (bytes memory data)
    {
        // Revert lookup if token has not been minted
        if (tokenId > ERC721Press(payable(targetPress)).lastMintedTokenId()) {
            revert Token_Not_Minted();
        }             
        // Will return bytes(0) if token has been burnt
        return SSTORE2.read(idToData[targetPress][tokenId - 1]);
    }

    /**
     * @notice Getter for acessing data for all data Ids for a given Press
     * @dev Fetches + returns stored bytes values from sstore2
     * @param targetPress ERC721Press to target
     * @return allData Array of all data
     */
    function readAllData(
        address targetPress
    )
        external
        view
        requireInitialized(targetPress)
        returns (bytes[] memory allData)
    {
        unchecked {
            allData = new bytes[](
                ERC721Press(payable(targetPress)).lastMintedTokenId()
            );

            for (uint256 i; i < settingsInfo[targetPress].storedCounter; ++i) {
                // Will return address(0) if token has been burnt
                allData[i] = SSTORE2.read(
                    idToData[targetPress][i]
                );
            }
        }
    }

    //////////////////////////////
    // PRICE + STATUS CHECKS
    //////////////////////////////

    /**
     * @notice Checks total mint price for a given Press x mintCaller x mintQuantity
     * @param targetPress Press contract to check mint price of
     * @param mintCaller Address of mintCaller to check pricing on behalf of
     * @param mintQuantity Quantity used to calculate total mint price
     * @return price Total price (in wei) needed to process transaction
     */
    function totalMintPrice(
        address targetPress,
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (uint256 price) {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic).getMintPrice(
                targetPress,
                mintCaller,
                mintQuantity
            );
    }

    /**
     * @notice Checks value of initialized variable in settingsInfo mapping for target Press
     * @param targetPress Press contract to check initialization status
     * @return initialized True/false bool if press is initialized
     */
    function isInitialized(
        address targetPress
    ) external view returns (bool initialized) {
        // Return false if targetPress has not been initialized
        if (settingsInfo[targetPress].initialized == 0) {
            return false;
        }

        return true;
    }

    //////////////////////////////
    // ACCESS CHECKS
    //////////////////////////////

    /**
     * @notice Checks mint access for a given mintQuantity + mintCaller
     * @param targetPress Press contract to check access for
     * @param mintCaller Address of mintCaller to check access for
     * @param mintQuantity Quantiy to check access for
     * @return mintAccess True/false bool
     */
    function canMint(
        address targetPress,
        address mintCaller,
        uint256 mintQuantity
    ) external view requireInitialized(targetPress) returns (bool mintAccess) {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic).getMintAccess(
                targetPress,
                mintCaller,
                mintQuantity
            );
    }

    /**
     * @notice Checks burn access for a given burn caller
     * @param targetPress Press contract to check access for
     * @param burnCaller Address of burnCaller to check access for
     * @param tokenId TokenId to check access for
     * @return burnAccess True/false bool
     */
    function canBurn(
        address targetPress,
        address burnCaller,
        uint256 tokenId
    ) external view requireInitialized(targetPress) returns (bool burnAccess) {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic).getBurnAccess(
                targetPress,
                burnCaller,
                tokenId
            );
    }

    /**
     * @notice Checks settings access for a given settings caller
     * @param targetPress Press contract to check access for
     * @param settingsCaller Address of settingsCaller to check access for
     * @return settingsAccess True/false bool
     */
    function canEditSettings(
        address targetPress,
        address settingsCaller
    )
        external
        view
        requireInitialized(targetPress)
        returns (bool settingsAccess)
    {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getSettingsAccess(targetPress, settingsCaller);
    }

    /**
     * @notice Checks dataCaller edit access for a given edit caller
     * @param targetPress Press contract to check access for
     * @param dataCaller Address of dataCaller to check access for
     * @return contractAccess True/false bool
     */
    function canEditContractData(
        address targetPress,
        address dataCaller
    )
        external
        view
        requireInitialized(targetPress)
        returns (bool contractAccess)
    {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getContractDataAccess(targetPress, dataCaller);
    }

    /**
     * @notice Checks dataCaller edit access for a given edit caller
     * @param targetPress Press contract to check access for
     * @param dataCaller Address of dataCaller to check access for
     * @param tokenId TokenId to check access for
     * @return tokenAccess True/false bool
     */
    function canEditTokenData(
        address targetPress,
        address dataCaller,
        uint256 tokenId
    ) external view requireInitialized(targetPress) returns (bool tokenAccess) {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getTokenDataAccess(targetPress, dataCaller, tokenId);
    }

    /**
     * @notice Checks payments access for a given caller
     * @param targetPress Press contract to check access for
     * @param paymentsCaller Address of paymentsCaller to check access for
     * @return paymentsAccess True/false bool
     */
    function canEditPayments(
        address targetPress,
        address paymentsCaller
    )
        external
        view
        requireInitialized(targetPress)
        returns (bool paymentsAccess)
    {
        return
            IERC721PressLogic(settingsInfo[targetPress].logic)
                .getPaymentsAccess(targetPress, paymentsCaller);
    }

    //////////////////////////////
    // DATA RENDERING
    //////////////////////////////

    /**
     * @notice ContractURI getter for a given Press.
     * @return uri String contractURI
     */
    function contractURI()
        external
        view
        requireInitialized(msg.sender)
        returns (string memory uri)
    {
        return
            IERC721PressRenderer(settingsInfo[msg.sender].renderer)
                .getContractURI(msg.sender);
    }

    /**
     * @notice TokenURI getter for a given Press + tokenId
     * @param tokenId TokenId to get uri for
     * @return uri String tokenURI
     */
    function tokenURI(
        uint256 tokenId
    ) external view requireInitialized(msg.sender) returns (string memory uri) {
        return
            IERC721PressRenderer(settingsInfo[msg.sender].renderer).getTokenURI(
                msg.sender,
                tokenId
            );
    }
}