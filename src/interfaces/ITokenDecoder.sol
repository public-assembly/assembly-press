// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITokenDecoder {
    function decodeTokenURI(bytes memory) external pure returns (string memory);
}