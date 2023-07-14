//   /**
//   * @dev Factory address => isAllowed bool
//   */
//   mapping(address => bool) internal _allowedFactories;    

// /// @notice Sets official factory for database
// function setOfficialFactory(address factory) external;

// /**
//     * @notice Getter for officialFactory status of an address. If true, can call `initializePress`
//     * @param target Address to check
//     */
// function isOfficialFactory(address target) external view returns (bool) {
//     return _officialFactories[target];
// }

// /**
// * @notice Checks if factory designated in setup is allowed
// */
// modifier requireAllowedFactory(address factory) {
//     if (_allowedFactories == false) {
//         revert Factory_Not_Allowed();
//     }

//     _;
// }    