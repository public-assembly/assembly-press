# Possible Remaining Changes

## Metadata renderer
- Store tokenURI & contractURI as bytes and then decode in read calls -> Decided against this for dev simplicity

## URI Minter
- Pass in bytes rather than string on customMint -> Decided against this for dev simplicity

To Change in order to generalize:

## Other functionality that could be added
- Remote Access control for wildcard minter role.
- Signature verication logic: Another module that you can opt in to using with this... another pass.
- would be cool to easily grab the drops salesconfig stuff:

## Bare minimum frontend??
- Create instance
- View your contracts (zora drops you own that have TokenUriMetadataRenderer)
- View your mints
- Consumer stuff - mint, update, etc.
- Ipfs uploader utility