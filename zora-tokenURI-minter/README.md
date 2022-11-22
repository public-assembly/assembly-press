# Custom Contracts for Jen Stark

To Change in order to generalize:

## Metadata renderer
- Change names of JenStark stuff -> DONE
- Line 79 / change to "wildcardaddy" - keep the special access mechanism -> DONE
- Allow wildcard per collection rather than global for renderer -> DONE
- Store tokenURI & contractURI as bytes and then decode in read calls -> Decided against this for dev simplicity

## URI Minter
- Change names of JenStark stuff -> DONE
- Add batch minting functionality -> DONE
- Pass in bytes rather than string -> Decided against this for dev simplicity

## Additional functionality
- Access control for wildcard minter role.
- Signature verication logic: Another module that you can opt in to using with this... another pass.
- would be cool to easily grab the drops salesconfig stuff:

## Bare minimum frontend??
- Create instance
- View your contracts (zora drops you own that have TokenUriMetadataRenderer)
- View your mints
- Consumer stuff - mint, update, etc.
- Ipfs uploader utility