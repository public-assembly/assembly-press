# How to Integrate to a ZORA Collection
1. Deploy TokenUriMetadataRenderer to chain of ur choice (ex: [Goerli deploy](https://goerli.etherscan.io/address/0xc2538e0f8fce1affc81135e2f6f67b2f0c30400a))
2. Deploy TokenUriMinter to chain of ur choice (ex: [Goerli deploy](https://goerli.etherscan.io/address/0x2c0f8aa33363ddf2cd662474b3e9dd40f5c924e1))
3. Deploy Zora Drop Contract (only available on Mainnet/Goerli atm), and pass in address of TokenUriMetadataRenderer for Metadata Renderer, and abi.encoded value of contractURI + wildcardAddress for Renderer Init

See screenshot below for how to use [abi.hashex.org](https://abi.hashex.org/) to create encoded init value for Zora Drop init:

![metadata_init](https://user-images.githubusercontent.com/93691906/203407825-d3eb202d-a385-4185-9118-d5f5f4ae03b1.png)

4. Grant "MINTER" role to TokenUriMinter from your Zora Drop Contract (ex: [Goerli txn](https://goerli.etherscan.io/tx/0x91589c65bb98d7a7517fdea482f754b57554c53edffe2f45e4310076bc0e72a2)) 
5. Call "customMint" function on TokenUriMinter contract and pass in Zora Drop Contract you are interacting with, address you want to mint to, and an array of all the tokenURIs you want to mint. The number of URIs you pass in will be the number of mints you are calling. make sure that msg.value = mint price x number of mints. (ex: [Goerli txn](https://goerli.etherscan.io/tx/0x01ef2f508e8f482e71bf8c20e0c90b427da4bf4cdf7840944d142a3551fbe1c4))

## Possible Remaining Changes

### Metadata renderer
- Store tokenURI & contractURI as bytes and then decode in read calls -> Decided against this for dev simplicity

### URI Minter
- Pass in bytes rather than string on customMint -> Decided against this for dev simplicity

### Other functionality that could be added
- Remote Access control for wildcard minter role.
- Signature verication logic: Another module that you can opt in to using with this... another pass.
- would be cool to easily grab the drops salesconfig stuff:

## Bare minimum frontend?
- Create instance
- View your contracts (zora drops you own that have TokenUriMetadataRenderer)
- View your mints
- Consumer stuff - mint, update, etc.
- Ipfs uploader utility
