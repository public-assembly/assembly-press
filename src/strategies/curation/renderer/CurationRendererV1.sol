// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*
PA PA PA PA
PA PA PA PA
PA PA PA PA
PA PA PA PA
*/

import {IERC721Press} from "../../../core/token/ERC721/interfaces/IERC721Press.sol";
import {IERC721PressLogic} from "../../../core/token/ERC721/interfaces/IERC721PressLogic.sol";
import {IERC721PressDatabase} from "../../../core/token/ERC721/interfaces/IERC721PressDatabase.sol";
import {ERC721Press} from "../../../core/token/ERC721/ERC721Press.sol";
import {IERC721PressRenderer} from "../../../core/token/ERC721/interfaces/IERC721PressRenderer.sol";
import {CurationMetadataBuilder} from "./CurationMetadataBuilder.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @title CurationRendererV1
/// @notice This is a modiified version of an earlier impl authored by Iain Nash
/// @dev Allows for initialization + editing of a string value for use in contractURI.image 
/// @dev Builds svg from onchain data for tokenURI.image value 
contract CurationRendererV1 is IERC721PressRenderer {

    //////////////////////////////////////////////////
    // TYPES
    //////////////////////////////////////////////////

    /// @notice Shared listing used for final decoded output in Curation strategy.
    /**
     * Struct breakdown. Values in parentheses are bytes.
     *
     * First slot
     * chainId (32) = 32 bytes
     * Second slot
     * tokenId (32) = 32 bytes    
     * Third slot
     * listingAddress (20) + sortOrder (12) = 32 bytes
     * Fourth slot
     * curator (20) + hasTokenId (1) = 21 bytes
     */
    struct Listing {
        /// @notice ChainID for curated contract
        uint256 chainId;        
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint256 tokenId;        
        /// @notice Address that is curated
        address listingAddress;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int96 sortOrder;
        /// @notice Address that curated this listing
        address curator;
        /// @notice If `tokenId` applies to the listing
        bool hasTokenId;
    }

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////    

    mapping(address => string) public contractUriImageInfo;

    //////////////////////////////////////////////////
    // ERRORS
    //////////////////////////////////////////////////    

    /// @notice Initialization coming from unauthorized contract
    error UnauthorizedInitializer();
    /// @notice msg.sender does not have access to adjust contractUriImage for given Press
    error No_Contract_Data_Access();        

    //////////////////////////////////////////////////
    // EVENTS
    //////////////////////////////////////////////////

    /// @notice Event emitted when contractUriImage updated
    /// @param targetPress ERC721Press being targeted
    /// @param sender msg.sender
    /// @param contractUriImage string value for contractURI.image
    event ContractUriImageUpdated(
        address targetPress,
        address sender,
        string contractUriImage
    );              

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
        if (IERC721PressDatabase(address(ERC721Press(payable(targetPress)).getDatabase())).canEditContractData(targetPress, msg.sender) == false) {
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

        // Build + cache Listing object for tokenId
        Listing memory listing = _buildListing(targetPress, tokenId);
        
        // Build properties JSON
        properties[1].key = "chainId";
        properties[1].value = Strings.toString(listing.chainId);
        properties[1].quote = true;    
        properties[2].key = "contract";
        properties[2].value = Strings.toHexString(listing.listingAddress);
        properties[2].quote = true;
        properties[3].key = "hasTokenId";
        properties[3].value = _hasTokenIdConverter(listing.hasTokenId);
        properties[3].quote = true;                
        properties[4].key = "tokenId";
        properties[4].value = Strings.toString(listing.tokenId);
        properties[4].quote = true;     
        properties[5].key = "sortOrder";
        properties[5].value = _sortOrderConverter(listing.sortOrder);
        properties[5].quote = true;                    
        properties[6].key = "curator";
        properties[6].value = Strings.toHexString(ERC721Press(payable(targetPress)).ownerOf(tokenId));
        properties[6].quote = true;           
                    
        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curation Receipt #", Strings.toString(tokenId));
        items[0].quote = true;
        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This non-transferable NFT represents a listing curated by ",
            Strings.toHexString(ERC721Press(payable(targetPress)).ownerOf(tokenId)),
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

    /// @dev Decodes stored bytes values into the values that were originally encoded for curation strategy
    /// @param data data to process
    function _decodeBytes(bytes memory data) internal pure returns (Listing memory) {
        // data format: chainId, tokenId, listingAddress, hasTokenId
        (
            uint256 chainId, 
            uint256 tokenId, 
            address listingAddress, 
            bool hasTokenId
        ) = abi.decode(data, (uint256, uint256, address, bool));

        return 
            Listing({
                chainId: chainId,
                tokenId: tokenId,
                listingAddress: listingAddress,
                hasTokenId: hasTokenId,
                curator: address(0),
                sortOrder: 0
            });
    }    

    /// @dev Builds + returns Listing struct stored bytes values into the values that were originally encoded for curation strategy
    /// @param targetPress Press to build Listing from
    /// @param tokenId tokenId to retrieve data for
    function _buildListing(address targetPress, uint256 tokenId) internal view returns (Listing memory) {
    
        // get database contract for given Press (tokenURI call is coming from ERC721Press)
        IERC721PressDatabase database = IERC721PressDatabase(ERC721Press(payable(targetPress)).getDatabase());

        // returns { bytes found at sstore2 pointer, int96 sortOrder}
        IERC721PressDatabase.TokenDataRetrieved memory tokenData = database.readData(targetPress, tokenId);       

        // decode data bytes data into partial Listing struct
        Listing memory partialListing = _decodeBytes(tokenData.storedData);

        // build + return rest of Listing struct
        return Listing({
            chainId: partialListing.chainId,
            tokenId: partialListing.tokenId,
            listingAddress: partialListing.listingAddress,
            hasTokenId: partialListing.hasTokenId,
            curator: ERC721Press(payable(targetPress)).ownerOf(tokenId),
            sortOrder: tokenData.sortOrder
        });
    }

    /////////////////////////
    // STRING HELPERS
    /////////////////////////

    // helper function for sortOrder metadata returns
    function _sortOrderConverter(int96 sortOrder) internal pure returns (string memory) {
        if (sortOrder >= 0) {
            return Strings.toString(uint256(uint96(sortOrder)));
        } else {
            return string.concat(
                "-",
                Strings.toString(uint256(uint96(-sortOrder)))
            );
        }
    }

    // helper function for hasTokenId metadata returns
    function _hasTokenIdConverter(bool hasTokenId) internal pure returns (string memory) {
        if (hasTokenId) {
            return "true";
        }
        return "false";
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

    function generateGridForAddress(
        address targetPress,
        address owner
    ) public pure returns (string memory) {
        uint16 saturationOuter = 25;

        uint256 squares = 0;
        uint256 freqDiv = 23;
        // uint256 hue = 168; // hardcoded at 168 but default value is 0

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({ size: 720, x: 0, y: 0, color: CurationMetadataBuilder._makeHSL({ h: 317, s: saturationOuter, l: 30 }) }),
            CurationMetadataBuilder._makeSquare({ size: 600, x: 30, y: 98, color: CurationMetadataBuilder._makeHSL({ h: 317, s: saturationOuter, l: 50 }) }),
            CurationMetadataBuilder._makeSquare({ size: 480, x: 60, y: 180, color: CurationMetadataBuilder._makeHSL({ h: 317, s: saturationOuter, l: 70 }) }),
            CurationMetadataBuilder._makeSquare({ size: 60, x: 90, y: 270, color: CurationMetadataBuilder._makeHSL({ h: 317, s: saturationOuter, l: 70 }) })
        );

        uint256 addr = uint160(uint160(owner));
        for (uint256 i = 0; i < squares * squares; i++) {
            addr /= freqDiv;
            if (addr % 3 == 0) {
                uint256 size = 720 / squares;
                svgInner = string.concat(
                    svgInner,
                    CurationMetadataBuilder._makeSquare({ size: size, x: (i % squares) * size, y: (i / squares) * size, color: "rgba(0, 0, 0, 0.4)" })
                );
            }
        }

        return MetadataBuilder.generateEncodedSVG(svgInner, "0 0 720 720", "720", "720");
    }    
}
        