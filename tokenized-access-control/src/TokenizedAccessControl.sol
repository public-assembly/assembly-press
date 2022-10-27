// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Ownable} from "openzeppelin-contracts/access/ownable.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";


contract TokenizedAccessControl is Ownable {

    struct AccessBucket {
        IERC721 erc721CurationPass;        
        IERC20 erc20CurationPass;
        uint16 erc721Quantity;
        uint16 erc20Quantity;
    }

    AccessBucket public MANAGER_BUCKET;

    AccessBucket public CURATOR_BUCKET;

    constructor(
        IERC721 _managerErc721CurationPass,
        IERC20 _managerErc20CurationPass,
        uint16 _managerErc721Quantity,
        uint16 _managerErc20Quantity,
        IERC721 _curatorErc721CurationPass,
        IERC20 _curatorErc20CurationPass,
        uint16 _curatorErc721Quantity,
        uint16 _curatorErc20Quantity
    ) {
        MANAGER_BUCKET.erc721CurationPass = _managerErc721CurationPass;
        MANAGER_BUCKET.erc20CurationPass = _managerErc20CurationPass;
        MANAGER_BUCKET.erc721Quantity = _managerErc721Quantity;
        MANAGER_BUCKET.erc20Quantity = _managerErc20Quantity;

        CURATOR_BUCKET.erc721CurationPass = _curatorErc721CurationPass;
        CURATOR_BUCKET.erc20CurationPass = _curatorErc20CurationPass;
        CURATOR_BUCKET.erc721Quantity = _curatorErc721Quantity;
        CURATOR_BUCKET.erc20Quantity = _curatorErc20Quantity;
    }

    function checkIfManager(address addressToCheck) public view returns (bool) {
        AccessBucket memory managerBucket = MANAGER_BUCKET;

        if ( managerBucket.erc721CurationPass.balanceOf(addressToCheck) > managerBucket.erc721Quantity) {
            if ( managerBucket.erc20CurationPass.balanceOf(addressToCheck) >  managerBucket.erc20Quantity) {
                return true;
            }
        }

        return false;
    }

    function checkIfCurator(address addressToCheck) public view returns (bool) {
        AccessBucket memory curatorBucket = CURATOR_BUCKET;

        if ( curatorBucket.erc721CurationPass.balanceOf(addressToCheck) > curatorBucket.erc721Quantity) {
            if ( curatorBucket.erc20CurationPass.balanceOf(addressToCheck) >  curatorBucket.erc20Quantity) {
                return true;
            }
        }

        return false;
    }    
}