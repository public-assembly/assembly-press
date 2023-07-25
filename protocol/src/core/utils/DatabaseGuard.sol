// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

abstract contract DatabaseGuard {
    /// @notice Storage for databaseImpl address
    address immutable databaseImpl;

    /// @notice Error if databaseImpl set to address(0) in constructor
    error Database_Impl_Cannot_Be_Zero();
    /// @notice Error if msg.sender not databaseImpl
    error Msg_Sender_Not_Database();

    /// @notice Checks if database is msg.sender
    modifier onlyDatabase() {
        if (msg.sender != databaseImpl) {
            revert Msg_Sender_Not_Database();
        }

        _;
    }

    /**
     * @notice Sets the implementation address upon deployment
     * @dev Implementation addresses cannot be updated after deployment
     */
    constructor(address _databaseImpl) {
        if (_databaseImpl == address(0)) revert Database_Impl_Cannot_Be_Zero();
        databaseImpl = _databaseImpl;
    }
}
