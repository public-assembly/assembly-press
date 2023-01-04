# AssemblyPress ✣

## THIS BRANCH IS UNDER CONSTRUCTION

#### REMAINING Work
1. Finish error documentation in ArtifactRenderer
2. re implement "promoteToEdition" esque function w/ custom renderer + logic
--did a very basic porting over of the old logic to the "EditionRenderer.sol" file. need to confirm that the way I overrode the "initializeToken" function to not do anything actually works
--also need to figure out where wee want to integrate a "createEdition" or "promoteToEdition" call. not sure
3. Redo factory + factory proxy impls
-- prob want to have first class functions for "deployArtifactory" and "editionalizeArtifact" or something like that
4. Tests
5. Deploy scripts
6. PA Bug bounty?
7. Front endsss

side note: theres definitely errors/inconsistencies when it comes to event usage + naming.
-- particularly when it comes to treating initialization functions

### REMAINING QUESTIONS
1. DefaultLogic.sol - Move maxSupply into Press.sol to prevent issues if a Press swithes logic impls? 
-- thought comes from https://metalabel.notion.site/040-Metalabel-Protocol-Walkthrough-64e892c31f6a4090a2c92088300b62c4
-- maybe allow a configurable "hardcap" on the collection size, and configurable "softcap" on the Logic side
2. add natspec/comment attributes for any code that was direct copy paste from elsewhere? ex: lots of zora util stuff 
3. should we add a "can use press?" check on the factory impl that requires ppl to mint an AssemblyPress free token?
-- this kinda kills hyperstructureness tho so prob not
4. should we update the "ArtifactCreated" event so that it stores the raw address + bytes for a given token?
-- if we dont do this, then that info will be lost forever whenever an Artifact is edited. which is kinda cool... but maybe we want to preserve

### NICE TO HAVES -- NON ESSENTIAL FOR V1
4. Press.sol -- add ability to withdraw non ETH funds
    -- does contract need FundsReciever import?  

### Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
