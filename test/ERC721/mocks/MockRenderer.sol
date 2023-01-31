// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IRenderer} from "../../../src/token/ERC721/interfaces/IRenderer.sol";

contract MockRenderer is IRenderer {
    
    string contractTestInit;
    string tokenTestInit;

    function tokenURI(uint256) external view override returns (string memory) {
        return tokenTestInit;
    }

    function contractURI() external pure override returns (string memory) {
        return "mockContractUri";
    }

    function initializeWithData(bytes memory rendererInit) external {
        (string memory test) = abi.decode(rendererInit, (string));
        contractTestInit = test;
    }    

    function initializeTokenMetadata(bytes memory tokenInit) external {
        (string memory test) = abi.decode(tokenInit, (string));
        tokenTestInit = test;        
    }
}
