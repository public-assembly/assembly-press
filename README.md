# AssemblyPress ℗ - v0.1 (May 4, 2023)

## Public Request for Comment (RFC)

[LINK TO PROTOCOL WALKTHROUGH](https://forum.public---assembly.com/t/assemblypress-walkthrough/335)

AssemblyPress v0.1 is the culmination of 8 months of on & off work that began with a very simple [curation protocol](https://etherscan.io/address/0x6422Bf82Ab27F121a043d6DE88b55FA39e2ea292#code) that serves as the backbone of [Present Material](https://www.presentmaterial.xyz/).

An [updated version](https://github.com/public-assembly/curation-protocol) was released months later alongside [Neosound](https://www.neosound.xyz/) that moved the protocol much closer to what was released today.

The full AssemblyPress (AP) architecture is now much more than a curation protocol. AP comprises two contract factories (ERC721 + ERC1155) designed to simplify the process in leveraging common token standards as onchain databases for any application. A more in-depth protocol walkthrough can be found [here](https://forum.public---assembly.com/t/draft-assemblypress-walkthrough/335).

Below is a (non-exhaustive) list of areas in need of review, bugs, and missing functionality that we hope to address before AP's v1.0 release. Public Assembly is an organization [building public goods](https://twitter.com/valcoholics1/status/1641244533265399810?s=20), and we are seeking help from the public in this review process.

We cannot guarantee that any bounties will be paid for help given during this review process, but we encourage anyone who pitches in to drop their ENS in any issue/pull-request they submit. Thank you for your help, we look forward to bringing this protocol to the public.


### General
- Prob want to add in generic multi call stuff to allow for more complex contract set up ability
-- Review for gas optimizations all over the place. Ex: removal of unnecessary value != 0 checks
-- For ERC721Press/ERC1155Press, all edit/update functions should be accessible by owner/permitted actors via external logic, EXCEPT for upgrade/transfer which should just be onlyOwner

### ERC721
- mintQuantity situation + maxSupply situation on erc721Press is funky
    - Restricted it mintQuantity to uint16 at some point bc we thought we were getting ran out of gas errors because of the data that gets passed in at large quantities but we think that was wrong
- Should updates to the logic contract that itself may have configurable access control extensions on it all have to go through the press contract?
    - ex: to update what access control module the logic contract is using, should you be calling setLogic on the underlying Press contract
        - Or should you be targeting the logic contract with some “update access control function”?
            - We imagine it should live at the logic contract level just not sure
- Missing tests 
    - deploy + upgrade paths
    - Additional config / metadata update things
    - Curation pause, freeze, sort orders, get listings for curator, tokenURI stuff
- The “HybridAccessWithFee” is really wack and just in there for withdraw testing purposes. Is there a way to make this more universal and helpful? we actually dont think so but tbd

### ERC1155
- Is it ok that the URI update event happens in the renderer rather than the underlying impl?
- EditionTokenLogic
    - Get rid of the mint cap check in the “canMintExisting” call?

### Local Development

1. `git clone https://github.com/public-assembly/AssemblyPress.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
