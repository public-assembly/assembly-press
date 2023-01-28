// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IContractLogic {  
    
    // ||||||||||||||||||||||||||||||||
    // ||| ERRORS |||||||||||||||||||||
    // ||||||||||||||||||||||||||||||||

    /// @notice checks if a certain address can transfer ownership of a given Press
    function canTransferOwnership(address targetPress, address transferCaller) external view returns (bool);    

    /// @notice checks if a certain address can upgrade the underlying implementation for a given Press
    function canUpgrade(address targetPress, address upgradeCaller) external view returns (bool);

    // informative view functions
    /// @notice returns price to mint a new token from a given press by a msg.sender for a given array of recipients at a given quantity
    function mintNewPrice(address targetPress, address mintCaller, address[] memory recipients, uint256 quantity) external view returns (uint256);   


    // initialize function
    /// @notice initializes logic file with arbitrary data
    function initializeWithData(bytes memory initData) external;    

    /// @notice checks if a certain address can access mint functionality for a given Press + recepients + quantity combination
    // creator vibes -- only one new colleciton at a time, and allows for provenance airdorps at time of new token minted
    //
    function canMintNew(
        address targetPress, 
        address mintCaller, 
        address[] memory recipients,
        uint256 quantities
    ) external view returns (bool);    

    /// @notice asdfd
    // collector vibes -- only allows for one recipient, but facilitates batch purchases with array of token ids / quantities
    //
    function canMintExisting(
        address targetPress,
        address recipient, 
        uint256[] memory tokenIds, 
        uint256[] memory quantities
    ) external view returns (bool);


}