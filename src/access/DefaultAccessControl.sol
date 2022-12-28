// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 @notice DefaultAccessControl
 @author Max Bochman
 */
contract DefaultAccessControl {

    // ||||||||||||||||||||||||||||||||
    // ||| TYPES ||||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Shared listing struct for minter + editor + admin
    struct Access {
        address minter;
        address editor;
        address admin;
    }

    // ||||||||||||||||||||||||||||||||
    // ||| STORAGE ||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||  

    /// @notice Press -> {minter, editor}
    mapping(address => Access) public accessInfo;     
    
    // ||||||||||||||||||||||||||||||||
    // ||| MODIFERS |||||||||||||||||||
    // ||||||||||||||||||||||||||||||||      

    /// @notice Checks if address can access a certain level
    modifier hasAccess(address target, address addressToCheck, uint256 accessLevel) {
        if (getAccessLevel(target, addressToCheck) < accessLevel) {
            revert No_Access();
        }

        _;
    }    
     

    // ||||||||||||||||||||||||||||||||
    // ||| EXTERNAL FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||          

    /* add initializer to this */
    /* add initializer to this */
    /* add initializer to this */
    /* add initializer to this */

    /// @notice Default initializer for collection level data of a specific zora ERC721 drop contract
    /// @notice contractURI must be set to non blank string value 
    /// @param data data to init with
    function initializeWithData(bytes memory accessInit) external {
        // data format: minter, editor, admin
        (
            address minterInit, 
            address editorInit,
            address adminInit
        ) = abi.decode(data, (address, address, address));

        // check if minter or editor set to zero address
        if (minterInit || editorInit || adminInit == address(0)) {
            revert Cannot_SetBlank();
        }

        // update values in accessInfo mapping
        accessInfo[msg.sender].minter = minterInit;
        accessInfo[msg.sender].editor = editorInit;
        accessInfo[msg.sender].admin = adminInit;
    }   

    /// @notice function to update access control logic
    /// @notice admin cannot be set to zero address
    /// @param newData new bytes value
    function updateAccessControlWithData(bytes memory newData) external hasAccess(msg.sender, tx.origin, ) {
        // data format: minter, editor, admin
        (
            address newMinter, 
            address newEditor,
            address newAdmin
        ) = abi.decode(data, (address, address, address));        


        // check if minter or editor set to zero address
        if (newMinter || newEditor || newAdmin == address(0)) {
            revert Cannot_SetBlank();
        }

        // update values in accessInfo mapping
        accessInfo[msg.sender].minter = minterInit;
        accessInfo[msg.sender].editor = editorInit;
        accessInfo[msg.sender].admin = adminInit;
    }

    /// @notice returns access level of a user address calling function
    /// @dev called via the external contract initializing access control
    function getAccessLevel(address accessMappingTarget, address addressToGetAccessFor)
        public
        view
        returns (uint256)
    {

        if (accessMappingTarget == address(0)) {
            revert TargetNotInitialized();
        }
        
        Access memory info = accessInfo[accessMappingTarget];

        if (info.admin == addressToGetAccessFor) {
            return 3;
        }        

        if (info.editor == addressToGetAccessFor) {
            return 2;
        }        

        if (info.minter == addressToGetAccessFor) {
            return 1;
        }                        

        return 0;
    }

}