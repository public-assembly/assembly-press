// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC1155PressLogic {
    ////////////////////////////////////////////////////////////
    // FUNCTIONS
    ////////////////////////////////////////////////////////////

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////
    /// @notice initializes renderer with arbitrary data
    function initializeWithData(address targetPress, bytes memory initData) external;
    /// @notice Checks if a certain address get edit contract data post data storage for a given Press
    function getContractDataAccess(address targetPress, address metadataCaller) external view returns (bool);
}
