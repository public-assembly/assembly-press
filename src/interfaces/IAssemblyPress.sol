// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721Drop} from "zora-drops-contracts/interfaces/IERC721Drop.sol";
import {Publisher} from "../Publisher.sol";

interface IAssemblyPress {
    error CantSet_ZeroAddress();

    event PublisherInitialized(address publisherAddress);
    event PublisherUpdated(address sender, address newPublisherAddress);
    event ZEditionMetadataRendererInitialized(address zoraProxyAddress);
    event ZEditionMetadataRendererUpdated(address sender, address newZEditionMetadataRendererAddress);
    event ZoraProxyAddressInitialized(address zoraProxyAddress);
    event ZoraProxyAddressUpdated(address sender, address newZoraProxyAddress);

    function initialize(address _initialOwner) external;

    function createPublication(
        string memory name,
        string memory symbol,
        address defaultAdmin,
        uint64 editionSize,
        uint16 royaltyBPS,
        address payable fundsRecipient,
        IERC721Drop.SalesConfiguration memory saleConfig,
        string memory contractURI,
        address accessControl,
        bytes memory accessControlInit,
        uint256 mintPricePerToken
    ) external returns (address);

    function setZoraCreatorProxyAddress(address newZoraNFTCreatorProxy) external;

    function setPublisher(Publisher newPublisherImplementation) external;

    function setzEditionMetadataRenderer(address newZEditionMetadataRenderer) external;
}
