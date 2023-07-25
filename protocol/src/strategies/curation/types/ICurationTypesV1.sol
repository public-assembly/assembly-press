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

/**
 * @title ICurationTypesV1
 * @notice Interface for types used across Curation strategy
 * @author Max Bochman
 * @author Salief Lewis
 */
interface ICurationTypesV1 {
    /**
     * @notice Shared listing used for final decoded output in Curation strategy.
     * @dev See below for struct breakdown. Values in parentheses are bytes.
     *
     * First slot: chainId (32) = 32 bytes
     * Second slot: tokenId (32) = 32 bytes
     * Third slot: listingAddress (20) + hasTokenId (1) = 21 bytes
     */
    struct Listing {
        /// @notice ChainID for curated contract
        uint256 chainId;
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint256 tokenId;
        /// @notice Address that is curated
        address listingAddress;
        /// @notice Whether tokenId is relevant for listing. 0 = false, 1 = true
        uint8 hasTokenId;
    }

    /**
     * @notice Shared enhanced listing sturct used for final decoded output in Curation strategy.
     * @dev Struct breakdown. Values in parentheses are bytes.
     * @dev Adds sortOrder + curator as values
     *
     * First slot: chainId (32) = 32 bytes
     * Second slot: tokenId (32) = 32 bytes
     * Third slot: listingAddress (20) + hasTokenId (1) =  21 bytes
     * Fourth slot: curator (20) = 20 bytes
     * Fifth slot: sortOrder (12) = 12 bytes
     */
    struct EnhancedListing {
        /// @notice ChainID for curated contract
        uint256 chainId;
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint256 tokenId;
        /// @notice Address that is curated
        address listingAddress;
        /// @notice If `tokenId` applies to the listing
        uint8 hasTokenId;
        /// @notice Address that curated this listing
        address curator;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int128 sortOrder;
    }
}
