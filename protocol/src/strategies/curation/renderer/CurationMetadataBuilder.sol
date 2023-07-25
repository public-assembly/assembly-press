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

import {Strings} from "micro-onchain-metadata-utils/lib/Strings.sol";

/**
 * @title CurationMetadataBuilder
 * @author Iain Nash
 * @notice Curation Metadata Builder Tools
 */
library CurationMetadataBuilder {
    /// @notice Arduino-style map function that takes x from a range and maps to a range of y.
    function map(uint256 x, uint256 xMax, uint256 xMin, uint256 yMin, uint256 yMax) internal pure returns (uint256) {
        return ((x - xMin) * (yMax - yMin)) / (xMax - xMin) + yMin;
    }

    /// @notice Makes a SVG square rect with the given parameters
    function _makeSquare(uint256 size, uint256 x, uint256 y, string memory color)
        internal
        pure
        returns (string memory)
    {
        return string.concat(
            '<rect x="',
            Strings.toString(x),
            '" y="',
            Strings.toString(y),
            '" width="',
            Strings.toString(size),
            '" height="',
            Strings.toString(size),
            '" style="fill: ',
            color,
            '" />'
        );
    }

    /// @notice Converts individual uint16 HSL values into concattendated string HSL
    function _makeHSL(uint16 h, uint16 s, uint16 l) internal pure returns (string memory) {
        return string.concat("hsl(", Strings.toString(h), ",", Strings.toString(s), "%,", Strings.toString(l), "%)");
    }
}
