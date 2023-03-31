# AssemblyPress ℗ - v0.0 (March 30, 2023)

## Public Request for Comment (RFC)

[LINK TO PROTOCOL WALKTHROUGH](https://forum.public---assembly.com/t/assemblypress-walkthrough/335)

AssemblyPress v0.0 is the culmination of 8 months of on & off work that began with a very simple [curation protocol](https://etherscan.io/address/0x6422Bf82Ab27F121a043d6DE88b55FA39e2ea292#code) that serves as the backbone of [Present Material](https://www.presentmaterial.xyz/).

An [updated version](https://github.com/public-assembly/curation-protocol) was released months later alongside [Neosound](https://www.neosound.xyz/) that moved the protocol much closer to what was released today.

The full AssemblyPress (AP) architecture is now much more than a curation protocol. AP comprises two contract factories (ERC721 + ERC1155) designed to simplify the process in leveraging common token standards as onchain databases for any application. A more in-depth protocol walkthrough can be found [here](https://forum.public---assembly.com/t/draft-assemblypress-walkthrough/335).

Below is a (non-exhaustive) list of areas in need of review, bugs, and missing functionality that we hope to address before AP's v1.0 release. Public Assembly is an organization [building public goods](https://twitter.com/valcoholics1/status/1641244533265399810?s=20), and we are seeking help from the public in this review process.

We cannot guarantee that any bounties will be paid for help given during this review process, but we encourage anyone who pitches in to drop their ENS in any issue/pull-request they submit. Thank you for your help, we look forward to bringing this protocol to the public.


### General
- Review the soul bound implementations for ERC721 (erc-5192) + ERC1155 (erc-5633)
    - Particularly the 1155 one where we made a bunch of custom edits to the 1155 solmate base
- Probably want to move the IAccessControlRegistry into this repo instead of importing from onchain to have better control of it
- Prob want to add in generic multi call stuff to allow for more complex contract set up ability
- Should we take out a lot of the functions in the ERC721Press + ERC1155Press interfaces to make them more flexible?
- Should we pick a specific pragma of solidity rather than ^0.8.16 ??
- clean up lib/imports/remappings

### ERC721
- Add a settable/initializable “description” field to CurationStorageV1 + update CurationMetadataRenderer so we can provide channel level descriptions for curation contracts
    - currently the description is generated programatically, doesn't allow for custom descriptions
- mintQuantity situation + maxSupply situation on erc721Press is funky
    - Restricted it mintQuantity to uint16 at some point bc we thought we were getting ran out of gas errors because of the data that gets passed in at large quantities but we think that was wrong
- Double check for redundant logic + events
    - ex: removal of unnecessary value != 0 checks
- Struct breakdown docs in ICurationLogic are weird even though helpful
- Missing byte struct breakdown for Curation Config
- Should updates to the logic contract that itself may have configurable access control extensions on it all have to go through the press contract?
    - ex: to update what access control module the logic contract is using, should you be calling setLogic on the underlying Press contract
        - Or should you be targeting the logic contract with some “update access control function”?
            - We imagine it should live at the logic contract level just not sure
- Missing tests 
    - deploy + upgrade paths
    - Additional config / metadata update things
    - Curation pause, freeze, sort orders, get listings for curator, tokenURI stuff
- The “HybridAccessWithFee” is really wack and just in there for withdraw testing purposes. Is there a way to make this more universal and helpful? we actually dont think so but tbd
- Update CurationLogic with a verson that uses assembly in `updateLogicWithData` to decode data more efficiently
    - could mean something like pass in one long packed bytes string and chop it up into corresponding listing chunks (still in bytes form) based on wtv the total length is / length of one packed one. and can get rid of the curator field cuz it’s soul bound and will always goes to msg sender. 
        - will require an update to ICurationLogic as well since the Listing struct may change (or not even be necessary anymore)
        - will also require an updated CurationMetadataRenderer

### ERC1155
- Check if withdraw implementation was done correctly
- Because erc1155press is using OwnableUpgradeable, it means that the entire “canTransferOwnership” check is irrelevant
    - Solutions
- Should we move away from using Ownable because of this? Set up custom owner() + setOwner() solution? Returning owner() is helpful for frontends
- Remove canTransferOwnership check
- Did I set up custom upgradeability correct?
- Is it ok that the URI update event happens in the renderer rather than the underlying impl?
- Seems like token + contract level logic might be  
- Create a better tokenEditionLogic that allows for configurable access control on initialization?
    - similar to how a separate module that controls access + mint price is initialized in CurationLogic
    - Might be unnecessary though because the whole point is the 1155 editions are really minimal with barely any access restrictions
- Create a better token/contractEditionLogic contracts that allow for token gating of access
    - ex: if you own PA token you can mintNew
- Add in an airdrop function that gets around the normal mint call which will check for mint price
- Add back in Batch mint? Or dont need?
- Add back Batch burn? Or dont need?
- Add in edit contract level name/symbol functionality?
- EditionTokenLogic
    - Get rid of the mint cap check in the “canMintExisting” call?

### Local Development

1. `git clone https://github.com/public-assembly/AssemblyPress.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
