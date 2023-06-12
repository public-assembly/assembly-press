# AssemblyPress ℗ - v0.3 (June 12, 2023)

## Public Request for Comment (RFC)

[LINK TO PROTOCOL WALKTHROUGH](https://forum.public---assembly.com/t/assemblypress-walkthrough/335)

AssemblyPress v0.2 is the culmination of 8 months of on & off work that began with a very simple [curation protocol](https://etherscan.io/address/0x6422Bf82Ab27F121a043d6DE88b55FA39e2ea292#code) that serves as the backbone of [Present Material](https://www.presentmaterial.xyz/).

An [updated version](https://github.com/public-assembly/curation-protocol) was released months later alongside [Neosound](https://www.neosound.xyz/) that moved the protocol much closer to what was released today.

The full AssemblyPress (AP) architecture is now much more than a curation protocol. AP comprises two contract factories (ERC721 + ERC1155) designed to simplify the process in leveraging common token standards as onchain databases for any application. A more in-depth protocol walkthrough can be found [here](https://forum.public---assembly.com/t/draft-assemblypress-walkthrough/335).

Please see the [issues section](https://github.com/public-assembly/AssemblyPress/issues) for a (non-exhaustive) list of areas in need of review, bugs, and missing functionality that we hope to address before AP's v1.0 release. 

Public Assembly is an organization [building public goods](https://twitter.com/valcoholics1/status/1641244533265399810?s=20), and we are seeking help from the public in this review process. We cannot guarantee that any bounties will be paid for help given during this review process, but we encourage anyone who pitches in to drop their ENS in any issue/pull-request they submit. Thank you for your help, we look forward to bringing this protocol to the public.


## Local Development

### Prerequisites
Ensure [Foundry](https://github.com/foundry-rs/foundry) is installed. Run the command `foundryup` to make sure it is up to date.

### Installation

Clone the repo and navigate to the directory. Install the project's dependencies with the following command:
```
$ forge install
```

Configure the environment variables necesary to run the test suite. Both a `MAINNET_RPC_URL` and `GOERLI_RPC_URL` should be supplied.

Next, run the test suite with the following command:
```
$ forge test
```
All tests should pass.
