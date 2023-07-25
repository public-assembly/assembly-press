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

import {IERC1155PressDatabase} from "../interfaces/IERC1155PressDatabase.sol";
import {IERC1155Press} from "../interfaces/IERC1155Press.sol";
import {ERC1155Press} from "../ERC1155Press.sol";

import {IERC1155PressLogic} from "../interfaces/IERC1155PressLogic.sol";
import {IERC1155PressRenderer} from "../interfaces/IERC1155PressRenderer.sol";

import {ERC1155PressDatabaseStorageV1} from "./storage/ERC1155PressDatabaseStorageV1.sol";
import {IERC1155PressDatabase} from "../interfaces/IERC1155PressDatabase.sol";

import "sstore2/SSTORE2.sol";

/**
 * @title ERC1155PressDatabaseSkeletonV1
 * @notice V1 generic database architecture. Strategy specific databases can inherit this to ensure compatibility with Assembly Press framework
 * @dev
 * @author Max Bochman
 * @author Salief Lewis
 */
abstract contract ERC1155PressDatabaseSkeletonV1 is ERC1155PressDatabaseStorageV1, IERC1155PressDatabase {
    ////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////

    /**
     * @notice Checks if target Press has been initialized to the database
     */
    modifier requirePressInitialized(address targetPress) {
        if (pressSettingsInfo[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }

        _;
    }

    /**
     * @notice Checks if target Press + tokenId has been initialized to the database
     */
    modifier requireTokenInitialized(address targetPress, uint256 tokenId) {
        if (tokenSettingsInfo[targetPress][tokenId].initialized != 1) {
            revert Token_Not_Initialized();
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
        // Cache msg.sender -- which should be a Factory if called correctly
        address factory = msg.sender;

        if (_officialFactories[factory] != true) {
            revert No_Initialize_Access();
        }

        // Set initialize status for Press => tokenId
        pressSettingsInfo[targetPress].initialized = 1;

        emit PressInitialized(factory, targetPress);
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
     * @notice Default logic initializer for a given Press
     * @dev Initializes settings for a given Press
     * @param databaseInit data to init with
     */
    function initializePressWithData(bytes memory databaseInit) external {
        // Cache msg.sender -- which is Press if called correctly
        address sender = msg.sender;

        if (pressSettingsInfo[sender].initialized != 1) {
            revert Press_Not_Initialized();
        }

        // Data format: pressLogic, pressLogicInit, pressRenderer, pressRendererInit
        (address pressLogic, bytes memory pressLogicInit, address pressRenderer, bytes memory pressRendererInit) =
            abi.decode(databaseInit, (address, bytes, address, bytes));

        // Sets ands initializes logic + renderer contracts
        _setPressLogic(sender, pressLogic, pressLogicInit);
        _setPressRenderer(sender, pressRenderer, pressRendererInit);
    }

    //////////////////////////////
    // PRESS SETTINGS
    //////////////////////////////

    /**
     * @notice Internal handler for setPressLogic function
     * @dev No access checks, enforce elsewhere
     * @param targetPress Press to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function _setPressLogic(address targetPress, address logic, bytes memory logicInit) internal {
        pressSettingsInfo[targetPress].logic = logic;
        IERC1155PressLogic(logic).initializeWithData(targetPress, logicInit);

        emit PressLogicUpdated(targetPress, logic);
    }

    /**
     * @notice Internal handler for setPressRenderer function
     * @dev RendererInit can be blank
     * @param targetPress Press to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function _setPressRenderer(address targetPress, address renderer, bytes memory rendererInit) internal {
        pressSettingsInfo[targetPress].renderer = renderer;
        IERC1155PressRenderer(renderer).initializeWithData(targetPress, rendererInit);

        emit PressRendererUpdated(targetPress, renderer);
    }

    //////////////////////////////
    // TOKEN SETTINGS
    //////////////////////////////

    /**
     * @notice Internal handler for setTokenLogic function
     * @dev No access checks, enforce elsewhere
     * @param targetPress Press to update logic for
     * @param tokenId tokenId to update logic for
     * @param logic Address of logic implementation
     * @param logicInit Data to init logic with
     */
    function _setTokenLogic(address targetPress, uint256 tokenId, address logic, bytes memory logicInit) internal {
        tokenSettingsInfo[targetPress][tokenId].logic = logic;
        // IERC721PressLogic(logic).initializeWithData(targetPress, logicInit);

        emit TokenLogicUpdated(targetPress, tokenId, logic);
    }

    /**
     * @notice Internal handler for setTokenRenderer function
     * @dev RendererInit can be blank
     * @param targetPress Press to update renderer for
     * @param tokenId tokenId to update renderer for
     * @param renderer Address of renderer implementation
     * @param rendererInit Data to init renderer with
     */
    function _setTokenRenderer(address targetPress, uint256 tokenId, address renderer, bytes memory rendererInit)
        internal
    {
        tokenSettingsInfo[targetPress][tokenId].renderer = renderer;
        // IERC721PressRenderer(renderer).initializeWithData(
        //     targetPress,
        //     rendererInit
        // );

        emit TokenRendererUpdated(targetPress, tokenId, renderer);
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
     * @param targetPress Press to target
     * @param tokenId tokenId to retrieve data for
     * @return data Data stored for given token
     */
    function readData(address targetPress, uint256 tokenId)
        external
        view
        requirePressInitialized(targetPress)
        returns (bytes memory data)
    {
        // Revert lookup if token has not been minted
        if (tokenId > ERC1155Press(payable(targetPress)).getNumMinted()) {
            revert Token_Not_Minted();
        }
        // Will return bytes(0) data if token has been burnt
        return SSTORE2.read(idToData[targetPress][tokenId - 1]);
    }

    /**
     * @notice Getter for acessing data for all data Ids for a given Press
     * @dev Fetches + returns stored bytes values from sstore2
     * @param targetPress ERC1155Press to target
     * @return allData Array of all data
     */
    function readAllData(address targetPress) external view returns (bytes[] memory allData) {
        if (pressSettingsInfo[targetPress].initialized != 1) {
            revert Press_Not_Initialized();
        }
        unchecked {
            allData = new bytes[](
                ERC1155Press(payable(targetPress)).getNumMinted()
            );

            for (uint256 i; i < pressSettingsInfo[targetPress].storedCounter; ++i) {
                // Will return address(0) if token has been burnt
                allData[i] = SSTORE2.read(idToData[targetPress][i]);
            }
        }
    }

    //////////////////////////////
    // ACCESS CHECKS
    //////////////////////////////

    /**
     * @notice Checks dataCaller edit access for a given edit caller
     * @param targetPress Press contract to check access for
     * @param dataCaller Address of dataCaller to check access for
     * @return contractAccess True/false bool
     */
    function canEditContractData(address targetPress, address dataCaller) external view returns (bool) {
        // Cache msg.sender
        // TODO: make _msgSender();
        address sender = msg.sender;

        if (pressSettingsInfo[sender].initialized != 1) {
            revert Press_Not_Initialized();
        }
        return IERC1155PressLogic(pressSettingsInfo[sender].logic).getContractDataAccess(sender, dataCaller);
    }

    //////////////////////////////
    // DATA RENDERING
    //////////////////////////////

    /**
     * @notice ContractURI getter for a given Press.
     * @return uri String contractURI
     */
    function contractURI() external view returns (string memory) {
        // Cache msg.sender -- Press if as intended
        address sender = msg.sender;

        if (pressSettingsInfo[sender].initialized != 1) {
            revert Press_Not_Initialized();
        }

        return IERC1155PressRenderer(pressSettingsInfo[sender].renderer).getContractURI(sender);
    }

    /**
     * @notice Uri getter for a given Press + tokenId
     * @param tokenId TokenId to get uri for
     * @return uri String uri
     */
    function uri(uint256 tokenId) external view returns (string memory) {
        // Cache msg.sender -- Press if as intended
        address sender = msg.sender;

        if (tokenSettingsInfo[sender][tokenId - 1].initialized != 1) {
            revert Token_Not_Initialized();
        }

        // if token doesnt have a renderer override, get uri from press renderer
        if (tokenSettingsInfo[sender][tokenId - 1].renderer == address(0)) {
            return IERC1155PressRenderer(pressSettingsInfo[sender].renderer).getTokenURI(sender, tokenId);
        }

        // if token does have a renderer override, get uri from token renderer
        return IERC1155PressRenderer(tokenSettingsInfo[sender][tokenId].renderer).getTokenURI(sender, tokenId);
    }
}
