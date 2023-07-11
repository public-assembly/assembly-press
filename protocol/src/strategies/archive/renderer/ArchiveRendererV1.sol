// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
                                                             .:^!?JJJJ?7!^..                    
                                                         .^?PB#&&&&&&&&&&&#B57:                 
                                                       :JB&&&&&&&&&&&&&&&&&&&&&G7.              
                                                  .  .?#&&&&#7!77??JYYPGB&&&&&&&&#?.            
                                                ^.  :PB5?7G&#.          ..~P&&&&&&&B^           
                                              .5^  .^.  ^P&&#:    ~5YJ7:    ^#&&&&&&&7          
                                             !BY  ..  ^G&&&&#^    J&&&&#^    ?&&&&&&&&!         
..           : .           . !.             Y##~  .   G&&&&&#^    ?&&&&G.    7&&&&&&&&B.        
..           : .            ?P             J&&#^  .   G&&&&&&^    :777^.    .G&&&&&&&&&~        
~GPPP55YYJJ??? ?7!!!!~~~~~~7&G^^::::::::::^&&&&~  .   G&&&&&&^          ....P&&&&&&&&&&7  .     
 5&&&&&&&&&&&Y #&&&&&&&&&&#G&&&&&&&###&&G.Y&&&&5. .   G&&&&&&^    .??J?7~.  7&&&&&&&&&#^  .     
  P#######&&&J B&&&&&&&&&&~J&&&&&&&&&&#7  P&&&&#~     G&&&&&&^    ^#P7.     :&&&&&&&##5. .      
     ........  ...::::::^: .~^^~!!!!!!.   ?&&&&&B:    G&&&&&&^    .         .&&&&&#BBP:  .      
                                          .#&&&&&B:   Y&&&&&&~              7&&&BGGGY:  .       
                                           ~&&&&&&#!  .!B&&&&BP5?~.        :##BP55Y~. ..        
                                            !&&&&&&&P^  .~P#GY~:          ^BPYJJ7^. ...         
                                             :G&&&&&&&G7.  .            .!Y?!~:.  .::           
                                               ~G&&&&&&&#P7:.          .:..   .:^^.             
                                                 :JB&&&&&&&&BPJ!^:......::^~~~^.                
                                                    .!YG#&&&&&&&&##GPY?!~:..                    
                                                         .:^^~~^^:.
*/

import {IERC1155Press} from "../../../core/token/ERC1155/interfaces/IERC1155Press.sol";
import {IERC1155PressLogic} from "../../../core/token/ERC1155/interfaces/IERC1155PressLogic.sol";
import {IERC1155PressDatabase} from "../../../core/token/ERC1155/interfaces/IERC1155PressDatabase.sol";
import {ERC1155Press} from "../../../core/token/ERC1155/ERC1155Press.sol";
import {IERC1155PressRenderer} from "../../../core/token/ERC1155/interfaces/IERC1155PressRenderer.sol";
import {ArchiveDatabaseV1} from "../database/ArchiveDatabaseV1.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";

/**
* @title ArchiveRendererV1
* @dev Allows for initialization + editing of a string value for use in contractURI.image 
*/
contract ArchiveRendererV1 is IERC1155PressRenderer {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////    

    mapping(address => string) public contractUriImageInfo;    

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when contractUriImage updated
    /// @param targetPress ERC1155Press being targeted
    /// @param sender msg.sender
    /// @param contractUriImage string value for contractURI.image
    event ContractUriImageUpdated(
        address targetPress,
        address sender,
        string contractUriImage
    );              

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Initialization coming from unauthorized contract
    error UnauthorizedInitializer();
    /// @notice msg.sender does not have access to adjust contractUriImage for given Press
    error No_Contract_Data_Access();        

    //////////////////////////////////////////////////
    // INITIALIZER
    //////////////////////////////////////////////////    

    /// @notice Initializes Press contractURI Image value
    /// @dev Can only be called by the database contract for a given Press
    /// @dev Called during the initialization process for a given Press
    function initializeWithData(address targetPress, bytes memory data) external {
        // Ensure that only the expected database contract is calling this function
        if (msg.sender != address(ERC1155Press(payable(targetPress)).getDatabase())) {
            revert UnauthorizedInitializer();
        }        
        
        (string memory contractUriImage) = abi.decode(data, (string));

        contractUriImageInfo[targetPress] = contractUriImage;

        emit ContractUriImageUpdated(targetPress, msg.sender, contractUriImage);        
    }

    //////////////////////////////////////////////////
    // CONTRACT URI ADMIN
    //////////////////////////////////////////////////    

    /// @notice Facilitates updating of image value returned in contractURI view call
    function setContractUriImage(address targetPress, string memory contractUriImage) external {
        
        // Check msg.sender contractUriImage access for given target Press
        if (IERC1155PressDatabase(address(ERC1155Press(payable(targetPress)).getDatabase())).canEditContractData(targetPress, msg.sender) == false) {
            revert No_Contract_Data_Access();
        }

        contractUriImageInfo[targetPress] = contractUriImage;

        emit ContractUriImageUpdated(targetPress, msg.sender, contractUriImage);
    }        

    //////////////////////////////////////////////////
    // CONTRACT URI + TOKEN URI VIEW FUNNCTIONS
    //////////////////////////////////////////////////    

    /// @notice return contractURI for a given Press
    /// @dev This is what Press database contract calls to get contractURI
    function getContractURI(address targetPress) external view returns (string memory) {
        ERC1155Press press = ERC1155Press(payable(targetPress));
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](3);

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(press.name());
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This content archive is owned by ",
            Strings.toHexString(press.owner())
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].quote = true;
        // The value assignment of contractURI.image could be any scheme that returns a string.
        //      This impl uses a simple string storage value but could also be an SVG generator
        items[2].value = contractUriImageInfo[targetPress];

        return MetadataBuilder.generateEncodedJSON(items);
    }

    /// @notice return tokenURI for a given Press + tokenId
    /// @dev This is what Press database contract calls to get tokenURI
    function getTokenURI(address targetPress, uint256 tokenId) external view returns (string memory) {

        // Get database contract for given Press (tokenURI call originates from ERC1155Press)
        ArchiveDatabaseV1 database = ArchiveDatabaseV1(address(ERC1155Press(payable(targetPress)).getDatabase()));

        // Returns bytes data stored for token
        bytes memory tokenData = database.readData(targetPress, tokenId);       

        // Decode bytes into Listing struct
        string memory stringTokenURI = abi.decode(tokenData, (string));

        return stringTokenURI;
    }
}
        