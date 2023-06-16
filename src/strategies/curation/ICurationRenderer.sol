// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICuratationRenderer {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||


    /// @notice Datatype decoded to in curation strategy
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * frozenAt (32) = 32 bytes
     * Second slot
     * priceToStore (32) = 32 bytes
     * Third slot
     * logic (20) + numAdded (5) + numRemoved (5) + initialized (1) + isPaused (1) = 32 bytes
     * Fourth slot
     * renderer (20) = 20 bytes  
     */
    struct Settings {
        /// @notice timestamp that the database is frozen at (if never, frozen = 0)
        uint256 frozenAt;
        /// @notice price to store new data
        uint256 priceToStore;   
        /// @notice Address of the logic contract
        address logic;
        /// Stores virtual mapping array length parameters
        /// @notice Array total size (total size)
        uint40 numAdded;
        /// @notice Array active size = numAdded - numRemoved
        /// @dev Blank entries are retained within array
        uint40 numRemoved;
        /// @notice initialized uint. 0 = not initialized, 1 = initialized
        uint8 initialized;
        /// @notice If database is paused by the owner
        bool isPaused;
        /// @notice Address of the renderer contract
        address renderer;
    }

    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory rendererInit) external;
}