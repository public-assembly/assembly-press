// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

import {ICurationLogic} from "../interfaces/ICurationLogic.sol";
import {ICurationInfo} from "../interfaces/ICurationInfo.sol";
import {ERC721Press} from "../../../ERC721Press.sol";
import {IERC721Press} from "../../../core/interfaces/IERC721Press.sol";
import {IERC721PressRenderer} from "../../../core/interfaces/IERC721PressRenderer.sol";
import {CurationMetadataBuilder} from "./CurationMetadataBuilder.sol";
import {MetadataBuilder} from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import {MetadataJSONKeys} from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

/// @title CurationMetadataRenderer
/// @notice This is a modiified version of an earlier impl authored by Iain Nash
contract CurationMetadataRenderer is IERC721PressRenderer {
    function initializeWithData(bytes memory initData) public {}

    function makeHSL(
        uint16 h,
        uint16 s,
        uint16 l
    ) internal pure returns (string memory) {
        return string.concat("hsl(", Strings.toString(h), ",", Strings.toString(s), "%,", Strings.toString(l), "%)");
    }

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
    ) public view returns (string memory) {
        uint16 saturationOuter = 25;

        uint256 squares = 0;
        uint256 freqDiv = 23;
        uint256 hue = 168;

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({ size: 720, x: 0, y: 0, color: makeHSL({ h: 317, s: saturationOuter, l: 30 }) }),
            CurationMetadataBuilder._makeSquare({ size: 600, x: 30, y: 98, color: makeHSL({ h: 317, s: saturationOuter, l: 50 }) }),
            CurationMetadataBuilder._makeSquare({ size: 480, x: 60, y: 180, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) }),
            CurationMetadataBuilder._makeSquare({ size: 60, x: 90, y: 270, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) })
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

    function contractURI() external view returns (string memory) {
        ERC721Press press = ERC721Press(payable(msg.sender));
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](3);

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat(press.name());
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This curation contract is owned by ",
            Strings.toHexString(press.owner()),
            "\\n\\nThe tokens in this collection provide proof-of-curation and are non-transferable."
            "\\n\\nThis curation protocol is a project of Public Assembly."
            "\\n\\nTo learn more, visit: https://public---assembly.com/"
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].quote = true;
        items[2].value = generateGridForAddress(msg.sender, press.owner());

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        // get logic contract for given Press (tokenURI call is coming from ERC721Press)
        ICurationLogic curator = ICurationLogic(address(IERC721Press(msg.sender).getLogic()));

        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4);
        MetadataBuilder.JSONItem[] memory properties = new MetadataBuilder.JSONItem[](7);
        ICurationLogic.Listing memory listing = curator.getListing(msg.sender, tokenId);

        properties[1].key = "contract";
        properties[1].value = Strings.toHexString(listing.listingAddress);
        properties[1].quote = true;
        properties[2].key = "selectedTokenId";
        properties[2].value = Strings.toString(listing.tokenId);
        properties[2].quote = true;        
        properties[3].key = "curator";
        properties[3].value = Strings.toHexString(ERC721Press(payable(msg.sender)).ownerOf(tokenId));
        properties[3].quote = true;                          
        properties[4].key = "sortOrder";
        properties[4].value = sortOrderConverter(listing.sortOrder);
        properties[4].quote = true; 
        properties[5].key = "hasTokenId";
        properties[5].value = hasTokenIdConverter(listing.hasTokenId);
        properties[5].quote = true;        
        properties[6].key = "chainId";
        properties[6].value = Strings.toString(listing.chainId);
        properties[6].quote = true;    

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curation Receipt #", Strings.toString(tokenId));
        items[0].quote = true;
        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This non-transferable NFT represents a listing curated by ",
            Strings.toHexString(ERC721Press(payable(msg.sender)).ownerOf(tokenId)),
            "\\n\\nYou can remove this record of curation by burning the NFT. "
            "\\n\\nThis curation protocol is a project of Public Assembly."
            "\\n\\nTo learn more, visit: https://public---assembly.com/"
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = generateGridForAddress(msg.sender, ERC721Press(payable(msg.sender)).ownerOf(tokenId));
        items[2].quote = true;
        items[3].key = MetadataJSONKeys.keyProperties;
        items[3].value = MetadataBuilder.generateJSON(properties);
        items[3].quote = false;

        return MetadataBuilder.generateEncodedJSON(items);
    }

    // ||||||||||||||||||||||||||||||||
    // ||| INTERNAL FUNCTIONS |||||||||
    // ||||||||||||||||||||||||||||||||  

    // helper function for sortOrder metadata returns
    function sortOrderConverter(int32 sortOrder) internal pure returns (string memory) {
        if (sortOrder >= 0) {
            return Strings.toString(uint256(uint32(sortOrder)));
        } else {
            return string.concat(
                "-",
                Strings.toString(uint256(uint32(-sortOrder)))
            );
        }
    }

    // helper function for hasTokenId metadata returns
    function hasTokenIdConverter(bool hasTokenId) internal pure returns (string memory) {
        if (hasTokenId) {
            return "true";
        }
        return "false";
    }
}