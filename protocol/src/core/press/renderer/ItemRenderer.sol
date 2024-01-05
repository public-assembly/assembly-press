// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "sstore2/SSTORE2.sol";
import "solidity-bytes-utils/BytesLib.sol";

/**
 * @title ItemRenderer
 */
contract ItemRenderer {

    error Invalid_Source_Data();
    error Invalid_Data_Type();

    enum DataTypes {
        STRING,
        NFT
    }

    function decodeUri(address pointer) public returns (string memory uri) {
        (uint16 dataType, bytes memory data)  = extractType(SSTORE2.read(pointer));
        if (dataType > uint16(DataTypes.NFT)) revert Invalid_Data_Type();
        if (dataType == uint16(DataTypes.STRING)) return decodeString()

    }

    function extractType(bytes memory data) public pure returns (uint16 dataType, bytes memory data) {
        uint256 length = data.length;
        // Get data type
        bytes memory rawSliceForType = BytesLib.slice(data, 0, 2);
        bytes2 cleanedSliceForType = bytes2(rawSlice);        
        dataType = uint16(cleanedSlice);            
        // Get data
        data = BytesLib.slice(data, 2, length - 2);          
    }

    function decodeString(bytes memory data) public pure returns (string memory str) {
        return string(data);
    }

    function decodeNft(bytes memory data) public pure 
        returns (
            uint256 chainId, 
            address tokenContract, 
            uint256 tokenId, 
            bool hasId
        ) 
    {
        (
            chainId, 
            tokenContract, 
            tokenId,
            hasId
        ) = abi.decode(data, (uint256, address, uint256, bool));

        return (chainId, tokenContract, tokenId, hasId);
    }





}

