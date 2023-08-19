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
    error Input_Length_Mistmatch();    
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
        address routerImpl,
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

    function isTransferable(uint256 tokenId) external returns (bool);
    
    // /// @notice Batch-mint tokens to a designated recipient
    // function mint(address recipient, uint256 quantity) external;
    // /// @notice Burn specific tokenId. Reduces totalSupply
    // function burn(uint256 tokenId) external;
    // /// @notice Burn multiple tokenIds. Reduces totalSupply
    // function burnBatch(uint256[] memory tokenIds) external;

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////

    // /// @notice Getter for AP721 owner
    // function owner() external view returns (address);
    // /// @notice Contract uri getter
    // function contractURI() external view returns (string memory);
    // /// @notice Token uri getter
    // function uri() external view returns (string memory);    
    // /// @dev Get royalty information for token
    // /// @param _tokenId the NFT asset queried for royalty information
    // /// @param _salePrice the sale price of the NFT asset specified by _tokenId
    // function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    //     external
    //     view
    //     returns (address receiver, uint256 royaltyAmount);
    // /// @notice ERC165 supports interface
    // /// @param interfaceId interface id to check if supported
    // function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
