# AssemblyPress ✣

## Overview
The contracts in this repo extend the [zora-drops-contracts](https://github.com/ourzora/zora-drops-contracts) and faciliate the creation of creator-owned minting contracts that provide very high levels of flexibility to control both metadata + metadata schema's for each token upon mint. Also leverages the modular + remote onchain access control enabled by the contracts in this repo [repo](https://github.com/public-assembly/onchain/tree/master/tokenized-access-control) to administer access to deployed contracts minting + editing functionality. Still a WIP as of 221212.

Here is a [video overview](https://www.loom.com/share/410dd99fb0ac4712b9f687666095efd9) of the basic architecture + usage. More information can be found ine Public Assembly [forum post](https://forum.public---assembly.com/t/assemblypress-sol-walkthrough-still-a-wip-but-functional-on-goerli/126) about this architecture

## Contracts
**AssemblyPress.sol**: Contract factory that extends ZoraNFTCreatorProxy and intializes a configurable minting contract for the deployer. Access control + contractURI is initialized in the deployment process, which is triggered by the "createPublication" function

**Publisher.sol**: External metadata registry + minting module from which all publication + editing occurs for contracts created through AssemblyPress.sol. Singular or batch minting/editing happens in the "publish" + "edit" functions respectively

**DefaultMetadataDecoder.sol**: Most basic tokenDecoder/metadataRenderer (still figuring out name) that converts bytes encoded string tokenURI values into strings and returns that value when tokenURI is called on the appropriate zora minting contract

**IDefaultMetadataDecoder (need to change name of this)**: You can create your own schema for decoding the bytes encoded metadata stored by the Publisher upon mint in PublisherStorage by writing a module that fits this interface and setting the value of your tokens' artifactDetails.artifactRenderer upon mint


## Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
