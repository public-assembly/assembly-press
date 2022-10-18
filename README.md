# Onchain Modules ⧉⥇⧉

## Overview
This repo contains small util implementations writtein in solidity that can be used to augment various existing onchain infrastructure    

## Contents
1. zora-tiered-pricing-minter: custom minting module extending standard functionality provided by the [zora-drops-contracts](https://github.com/ourzora/zora-drops-contracts) to allow for different pricing tiers based on mint quantity

## Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into desired module folder (ex: `cd zora-tiered-pricing-minter`)
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`

1. Individual curation contracts are ERC721 collections themselves, with curators receiving a non-transferable `listingRecord` that contains the information of the `Listing` they have curated. Curators can "remove" a Listing by burning their listingRecords
2. Factory allows for easy creation of individual curation contracts
3. Active Listings on a given curation contract can be retrieved by the `getListings()` view call on a given **Curator.sol** proxy, or by using NFT indexers to gather data on all `curationReciepts` that have been minted from a given curation contract
4. Listings contain the data specified in the `Listing` struct found in [ICurator.sol](https://github.com/public-assembly/curation-protocol/blob/main/src/interfaces/ICurator.sol)