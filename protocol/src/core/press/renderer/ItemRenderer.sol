// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "sstore2/SSTORE2.sol";

/**
 * @title ItemRenderer
 */
contract ItemRenderer {

    error Invalid_Type_Data();

    function decodeUri(address pointer) public returns (string memory uri) {
        bytes memory data = 
    }


    function extractType(bytes calldata data) public pure returns (uint16 numType) {
        if (data.length < 2) revert Invalid_Type_Data();
        bytes memory rawSlice = data[0:2];
        bytes2 cleanedSlice = bytes2(rawSlice);        
        numType = uint16(cleanedSlice);            
    }



}

