# AssemblyPress ✣

## THIS BRANCH IS UNDER CONSTRUCTION

[Work related directly to protocol development has been converted into issues]

### REMAINING
--> Should we conduct a Public Assembly bug bounty/community audit?
--> What is the process of developing a frontend(s) for this protocol?

### QUESTIONS
1. DefaultLogic.sol 
-- should maxSupply move into ERC721Press to prevent issues if a Press swithes logic implementations? 
-- thought comes from https://metalabel.notion.site/040-Metalabel-Protocol-Walkthrough-64e892c31f6a4090a2c92088300b62c4
-- maybe allow a configurable "hardcap" on the collection size, and configurable "softcap" on the Logic side

2. Add natspec/comment attributes for any code that was direct copy paste from elsewhere? ex: lots of zora util stuff 

3. Should we add a "can use press?" check on the factory impl that requires ppl to mint an AssemblyPress free token?
-- this kinda kills hyperstructureness tho so prob not

4. Should we update the "ArtifactCreated" event so that it stores the raw address + bytes for a given token?
-- if we dont do this, then that info will be lost forever whenever an Artifact is edited. which is kinda cool... but maybe we want to preserve it

### NICE TO HAVES -- NON ESSENTIAL FOR V1
--> Add ability to withdraw non ETH funds from ERC721Press
--> Does the contract need to import FundsReciever?

### Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
