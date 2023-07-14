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

import {IERC721PressFeeModule} from "../../../core/token/ERC721/interfaces/IERC721PressFeeModule.sol";
import {IERC721} from "openzeppelin-contracts/interfaces/IERC721.sol";

/**
* @title TokenGateFeeModule
* @notice tbd
* @dev tbd
*/
contract TokenGateFeeModule is IERC721PressFeeModule {

    //////////////////////////////////////////////////
    // STORAGE
    //////////////////////////////////////////////////    

    address erc721Gate;
    uint256 feeForNonHolders;
    address feeRecipient;

    //////////////////////////////////////////////////
    // CONSTRUCTOR
    //////////////////////////////////////////////////    

    constructor(address _erc721Gate, uint256 _feeForNonHolders, address _feeRecipeint) {
        erc721Gate = _erc721Gate;
        feeForNonHolders = _feeForNonHolders;
        feeRecipient = _feeRecipeint;
    }

    //////////////////////////////////////////////////
    // FUNCTIONS
    //////////////////////////////////////////////////     

    //////////////////////////////
    // WRITE FUNCTIONS
    //////////////////////////////    

    //////////////////////////////
    // READ FUNCTIONS
    //////////////////////////////    

    function getFeeInstructions(address targetPress, address user, uint256 storageSlots) external view returns (address, uint256) {
        return (address(0), 0);
    }    

    // function getFeeInstructions(address targetPress, address user, uint256 storageSlots) external view returns (address, uint256) {
    //     // If user doesnt own token, has to pay fee. If they do, no fee required        
    //     if (IERC721(erc721Gate).balanceOf(user) == 0) {
    //         return (feeRecipient, feeForNonHolders);
    //     } else {
    //         return (feeRecipient, feeForNonHolders);
    //     }
    // }
}  