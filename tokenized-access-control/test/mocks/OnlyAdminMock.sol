// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IAccessControlRegistry} from "../../src/interfaces/IAccessControlRegistry.sol";
import {Ownable} from "openzeppelin-contracts/access/ownable.sol";

contract OnlyAdminMock is Ownable {

    error NO_AC_INITIALIZED();

    address public accessControlProxy;

    function initializeAccessControl(
        address accessControl,
        address admin
    ) public onlyOwner returns (address) {

        bytes memory accessControlInit = abi.encode(
            admin
        );

        IAccessControlRegistry(accessControl).initializeWithData(accessControlInit);

        accessControlProxy = accessControl;

        return(admin);
    }

    function getAccessLevelForUser() external view returns (uint256) {

        if (accessControlProxy == address(0)) {
            revert NO_AC_INITIALIZED();
        }

        return IAccessControlRegistry(accessControlProxy).getAccessLevel(address(this), msg.sender);
    }

    function userAccessTest() external view returns (bool) {

        if (accessControlProxy == address(0)) {
            revert NO_AC_INITIALIZED();
        }

        if (IAccessControlRegistry(accessControlProxy).getAccessLevel(address(this), msg.sender) != 0) {
            return true;
        }

        return false;
    }

    function managerAccessTest() external view returns (bool) {

        if (accessControlProxy == address(0)) {
            revert NO_AC_INITIALIZED();
        }

        if (IAccessControlRegistry(accessControlProxy).getAccessLevel(address(this), msg.sender) > 1) {
            return true;
        }

        return false;
    }    

    function adminAccessTest() external view returns (bool) {

        if (accessControlProxy == address(0)) {
            revert NO_AC_INITIALIZED();
        }

        if (IAccessControlRegistry(accessControlProxy).getAccessLevel(address(this), msg.sender) > 2) {
            return true;
        }

        return false;
    }                        

}