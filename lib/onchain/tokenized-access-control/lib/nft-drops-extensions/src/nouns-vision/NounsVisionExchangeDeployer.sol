// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ZoraNFTCreatorV1} from "zora-drops-contracts/ZoraNFTCreatorV1.sol";
import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {SharedNFTLogic} from "zora-drops-contracts/utils/SharedNFTLogic.sol";
import {NounsVisionExchangeMinterModule} from "./NounsVisionExchangeMinterModule.sol";

contract NounsVisionExchangeDeployer {
    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable admin,
        address creator,
        SharedNFTLogic sharedNFTLogic,
        IERC721Drop sourceContract
    ) {
        NounsVisionExchangeMinterModule exchangeModule = new NounsVisionExchangeMinterModule(
                IERC721Drop(sourceContract),
                sharedNFTLogic,
                description
            );
        ZoraNFTCreatorV1(creator).setupDropsContract(
            name,
            symbol,
            admin,
            // edition size
            editionSize,
            // royalty bps
            royaltyBPS,
            admin,
            IERC721Drop.SalesConfiguration({
                publicSaleStart: 0,
                publicSaleEnd: 0,
                presaleStart: 0,
                presaleEnd: 0,
                publicSalePrice: 0,
                maxSalePurchasePerAddress: 0,
                presaleMerkleRoot: 0x0
            }),
            exchangeModule,
            ""
        );
    }
}
