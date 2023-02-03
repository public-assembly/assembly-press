# AssemblyPress ℗

## THIS BRANCH IS UNDER CONSTRUCTION

### Current Questions/Issues/Areas to Improve (NOT EXHAUSTIVE)

General
- Should we remove stuff (specifically a bunch of the read calls) out of IERC721Press + IERC1155Press to give us more flexibility overtime with new impls?
- What pragma solidity should we use?

ERC1155
- Need extensive review on how I customized the solmate 1155 impl to enable soulbound functionality following eip-5633
- Need review on the withdraw functions which implement an internal tracking system to associate funds received with certain tokenIds
- Some of the imports stored in utils folders could/should just be direct imports from OZ (ex: OwnableUpgradeable)

ERC721
- Not sure how to implement EIP4096 for metadata updates — since metadata is updated through the external metadataRenderer but EIP4096 compliance requires event to be called from the erc721 contract
- Concerned with maxSupply living in an external contract. Could break contract if updated incorrectly?
    - Also is it ok being capped at uint64? This is what zora drops are capped at, but the erc1155 maxSuppies were generally capped at uint256
- Related, testing made it seem like I needed to restrict mintQuantity to uint16 due to the fact you pass in data in the mintWithData call, and you can run into gas comp failures at higher quantities?

Bugs
- Because erc1155press is using OwnableUpgradeable, it means that the entire “canTransferOwnership” check is irrelevant
    - Solutions
        - Should we move away from using Ownable because of this? Set up custom owner() + setOwner() solution? Returning owner() is helpful for frontends
        - Remove canTransferOwnership check

### Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
