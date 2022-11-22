# Onchain ⧉⥇⧉

## Overview
This repo contains modular implementations written in solidity that can be used to augment existing onchain infrastructure.

## Contents
**tokenized-access-control**: custom modules for public curation mechanisms to allow any token to be the access control mechanism for curators.

**zora-tiered-pricing-minter**: custom minting module extending standard functionality provided by the [zora-drops-contracts](https://github.com/ourzora/zora-drops-contracts) to allow for different pricing tiers based on mint quantity.

**zora-tokenURI-minter**: custom minting module extending standard functionality provided by the [zora-drops-contracts](https://github.com/ourzora/zora-drops-contracts) to allow for initialization of token metadata upon mint rather than upon contract deploy

## Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into desired module folder (ex: `cd zora-tiered-pricing-minter`)
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to confirm module folder + contents have been installed correctly
