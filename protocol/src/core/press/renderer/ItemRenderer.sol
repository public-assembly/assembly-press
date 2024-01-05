// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "sstore2/SSTORE2.sol";
import "solidity-bytes-utils/BytesLib.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

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

    function decodeUri(address pointer) public view returns (string memory uri) {
        (uint16 dataType, bytes memory data) = extractType(SSTORE2.read(pointer));
        if (dataType > uint16(DataTypes.NFT)) revert Invalid_Data_Type();
        if (dataType == uint16(DataTypes.STRING)) return decodeString(data);
        if (dataType == uint16(DataTypes.NFT)) return decodeNft(data);
    }

    function extractType(bytes memory data) public pure returns (uint16 typeData, bytes memory rawData) {
        uint256 length = data.length;
        // Get data type
        bytes memory rawSliceForType = BytesLib.slice(data, 0, 2);
        bytes2 cleanedSliceForType = bytes2(rawSliceForType);        
        typeData = uint16(cleanedSliceForType);            
        // Get data
        rawData = BytesLib.slice(data, 2, length - 2);          
    }

    function decodeString(bytes memory data) public pure returns (string memory str) {
        return string(data);
    }

    function decodeNft(bytes memory data) public pure returns (string memory nft) {
        (
            uint256 chainId, 
            address tokenContract, 
            uint256 tokenId,
            bool hasId
        ) = abi.decode(data, (uint256, address, uint256, bool));

        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4);

        items[0].key = "chainId";
        items[0].value = Strings.toString(chainId);
        items[0].quote = true;
        items[1].key = "tokenContract";
        items[1].value = Strings.toHexString(tokenContract);
        items[1].quote = true;
        items[2].key = "tokenId";
        items[2].value = Strings.toString(tokenId);
        items[2].quote = true;        
        items[3].key = "hasId";
        items[3].value = hasTokenIdConverter(hasId);
        items[3].quote = true;        

        nft = MetadataBuilder.generateEncodedJSON(items);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||  

    // helper function for hasTokenId metadata returns
    function hasTokenIdConverter(bool hasTokenId) internal pure returns (string memory) {
        if (hasTokenId) {
            return "true";
        }
        return "false";
    }    
}