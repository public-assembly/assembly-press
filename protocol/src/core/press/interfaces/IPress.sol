// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/* woah */

import {IPressTypesV1} from "../types/IPressTypesV1.sol";

interface IPress {

    ////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////

    event Collected(
        address sender,
        address recipient,
        uint256 tokenId,
        uint256 quantity,
        uint256 msgValue
    );

    ////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////

    /// @notice Error when msg.sender is not the stored database impl
    error Sender_Not_Router();
    /// @notice Error when inputting arrays with non matching length
    error Input_Length_Mismatch();    
    /// @notice
    error No_Collect_Access();
    /// @notice
    error Incorrect_Msg_Value();
    /// @notice Error when attempting to create copies of non-fungible token
    error Non_Fungible_Token();    
    /// @notice Error when attempting to transfer non-transferable token
    error Non_Transferable_Token();
    /// @notice Error when attempting to withdraw eth balance from Press
    error ETHWithdrawFailed(address recipient, uint256 amount);

    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////

    /// @notice Initializes a PressProxy
    function initialize(        
        string memory pressName, 
        address initialOwner,
        address routerAddr,
        address logic,
        bytes memory logicInit,
        address renderer,
        bytes memory rendererInit,
        IPressTypesV1.AdvancedSettings memory advancedSettings
    ) external;
    function updatePressData(address press, bytes memory data) external payable returns (address);
    function storeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory);
    function overwriteTokenData(address sender, bytes memory data) external payable returns (uint256[] memory, address[] memory);
    function removeTokenData(address sender, bytes memory data) external payable returns (uint256[] memory);
    function collect(address recipient, uint256 tokenId, uint256 quantity) external payable;
    function collectBatch(address recipient, uint256[] memory tokenIds, uint256[] memory quantities) external payable;
    
    // TODO: 
    
    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////
    function isTransferable(uint256 tokenId) external returns (bool);
    
    // TODO: 
}
