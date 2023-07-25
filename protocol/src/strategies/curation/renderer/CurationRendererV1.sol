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

import {IERC721Press} from "../../../core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressLogic} from "../../../core/token/ERC721/interfaces/IERC721PressLogic.sol";
import {IERC721PressDatabase} from "../../../core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721Press} from "../../../core/token/ERC721/ERC721Press.sol";
import {IERC721PressRenderer} from "../../../core/token/ERC721/interfaces/IERC721PressRenderer.sol";
import {CurationDatabaseV1} from "../database/CurationDatabaseV1.sol";
import {ICurationTypesV1} from "../types/ICurationTypesV1.sol";
import {CurationMetadataBuilder} from "./CurationMetadataBuilder.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/**
 * @title CurationRendererV1
 * @notice This is a modiified version of an earlier impl authored by Iain Nash
 * @dev Allows for initialization + editing of a string value for use in contractURI.image
 * @dev Builds svg from onchain data for tokenURI.image value
 */
contract CurationRendererV1 is IERC721PressRenderer, ICurationTypesV1 {
    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////

    mapping(address => string) public contractUriImageInfo;

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when contractUriImage updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param contractUriImage string value for contractURI.image
    event ContractUriImageUpdated(address targetPress, address sender, string contractUriImage);

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
        if (msg.sender != address(ERC721Press(payable(targetPress)).getDatabase())) {
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
        if (
            IERC721PressDatabase(address(ERC721Press(payable(targetPress)).getDatabase())).canEditContractData(
                targetPress, msg.sender
            ) == false
        ) {
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
        ERC721Press press = ERC721Press(payable(targetPress));
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](3);

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(press.name());
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This channel is owned by ",
            Strings.toHexString(press.owner()),
            "\\n\\nThe tokens in this collection provide proof-of-curation and are non-transferable."
            "\\n\\nThis curation protocol is a project of Public Assembly."
            "\\n\\nTo learn more, visit: https://public---assembly.com/"
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].quote = true;
        // The value assignment of contractURI.image could be any scheme that returns a string
        //      this impl uses a simple string storage value but could also be an SVG generator
        items[2].value = contractUriImageInfo[targetPress];

        return MetadataBuilder.generateEncodedJSON(items);
    }

    /// @notice return tokenURI for a given Press + tokenId
    /// @dev This is what Press database contract calls to get tokenURI
    function getTokenURI(address targetPress, uint256 tokenId) external view returns (string memory) {
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4);
        MetadataBuilder.JSONItem[] memory properties = new MetadataBuilder.JSONItem[](7);

        // Build + cache EnhancedListing object for tokenId
        EnhancedListing memory listing = _buildListing(targetPress, tokenId);

        // Build properties JSON
        properties[1].key = "chainId";
        properties[1].value = Strings.toString(listing.chainId);
        properties[1].quote = true;
        properties[2].key = "contract";
        properties[2].value = Strings.toHexString(listing.listingAddress);
        properties[2].quote = true;
        properties[3].key = "hasTokenId";
        properties[3].value = Strings.toString(listing.hasTokenId);
        properties[3].quote = true;
        properties[4].key = "tokenId";
        properties[4].value = Strings.toString(listing.tokenId);
        properties[4].quote = true;
        properties[5].key = "sortOrder";
        properties[5].value = _sortOrderConverter(listing.sortOrder);
        properties[5].quote = true;
        properties[6].key = "curator";
        properties[6].value = Strings.toHexString(listing.curator);
        properties[6].quote = true;

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curation Receipt #", Strings.toString(tokenId));
        items[0].quote = true;
        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This non-transferable NFT represents a listing curated by ",
            Strings.toHexString(listing.curator),
            "\\n\\nYou can remove this record of curation by burning the NFT. "
            "\\n\\nThis curation protocol is a project of Public Assembly."
            "\\n\\nTo learn more, visit: https://public---assembly.com/"
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = generateGridForAddress(targetPress, ERC721Press(payable(targetPress)).ownerOf(tokenId));
        items[2].quote = true;
        items[3].key = MetadataJSONKeys.keyProperties;
        items[3].value = MetadataBuilder.generateJSON(properties);
        items[3].quote = false;

        return MetadataBuilder.generateEncodedJSON(items);
    }

    //////////////////////////////////////////////////
    // INTERNAL HELPERS
    //////////////////////////////////////////////////

    /////////////////////////
    // LISTING HELPERS
    /////////////////////////

    /// @dev Builds + returns Listing struct stored bytes values into the values that were originally encoded for curation strategy
    /// @param targetPress Press to build Listing from
    /// @param tokenId tokenId to retrieve data for
    function _buildListing(address targetPress, uint256 tokenId) internal view returns (EnhancedListing memory) {
        // Get database contract for given Press (tokenURI call originates from ERC721Press)
        CurationDatabaseV1 database = CurationDatabaseV1(address(ERC721Press(payable(targetPress)).getDatabase()));

        // Returns bytes data stored for token
        bytes memory tokenData = database.readData(targetPress, tokenId);

        // Decode bytes into Listing struct
        Listing memory listing = abi.decode(tokenData, (Listing));

        // Build + return EnhancedListing struct
        return EnhancedListing({
            chainId: listing.chainId,
            tokenId: listing.tokenId,
            listingAddress: listing.listingAddress,
            hasTokenId: listing.hasTokenId,
            curator: ERC721Press(payable(targetPress)).ownerOf(tokenId),
            sortOrder: database.slotToSort(targetPress, (tokenId - 1))
        });
    }

    /////////////////////////
    // STRING HELPERS
    /////////////////////////

    // Helper function for sortOrder metadata returns
    function _sortOrderConverter(int128 sortOrder) internal pure returns (string memory) {
        if (sortOrder >= 0) {
            return Strings.toString(uint256(uint128(sortOrder)));
        } else {
            return string.concat("-", Strings.toString(uint256(uint128(-sortOrder))));
        }
    }

    /////////////////////////
    // TOKEN URI SVG HELPERS
    /////////////////////////

    function _getTotalSupplySaturation(address targetPress) public view returns (uint16) {
        try ERC721Press(payable(targetPress)).totalSupply() returns (uint256 supply) {
            if (supply > 10000) {
                return 100;
            }
            if (supply > 1000) {
                return 75;
            }
            if (supply > 100) {
                return 50;
            }
        } catch {}
        return 10;
    }

    function generateGridForAddress(address targetPress, address owner) public pure returns (string memory) {
        uint16 saturationOuter = 25;

        uint256 squares = 0;
        uint256 freqDiv = 23;
        // uint256 hue = 168; // hardcoded at 168 but default value is 0

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({
                size: 720,
                x: 0,
                y: 0,
                color: CurationMetadataBuilder._makeHSL({h: 317, s: saturationOuter, l: 30})
            }),
            CurationMetadataBuilder._makeSquare({
                size: 600,
                x: 30,
                y: 98,
                color: CurationMetadataBuilder._makeHSL({h: 317, s: saturationOuter, l: 50})
            }),
            CurationMetadataBuilder._makeSquare({
                size: 480,
                x: 60,
                y: 180,
                color: CurationMetadataBuilder._makeHSL({h: 317, s: saturationOuter, l: 70})
            }),
            CurationMetadataBuilder._makeSquare({
                size: 60,
                x: 90,
                y: 270,
                color: CurationMetadataBuilder._makeHSL({h: 317, s: saturationOuter, l: 70})
            })
        );

        uint256 addr = uint160(uint160(owner));
        for (uint256 i = 0; i < squares * squares; i++) {
            addr /= freqDiv;
            if (addr % 3 == 0) {
                uint256 size = 720 / squares;
                svgInner = string.concat(
                    svgInner,
                    CurationMetadataBuilder._makeSquare({
                        size: size,
                        x: (i % squares) * size,
                        y: (i / squares) * size,
                        color: "rgba(0, 0, 0, 0.4)"
                    })
                );
            }
        }

        return MetadataBuilder.generateEncodedSVG(svgInner, "0 0 720 720", "720", "720");
    }
}
