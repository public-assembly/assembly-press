# AssemblyPress ✣

## THIS BRANCH IS UNDER CONSTRUCTION

#### QUESTIONS
1. Do we like how _authorizeUpgrade is handled in Press.osl? didn't use ZORA upgradeArch, but looks like
    We are missing the functionaity thats provided in the zora upgrade gate
    https://github.com/ourzora/zora-drops-contracts/blob/main/src/FactoryUpgradeGate.sol
2. Do we like how we implemented a very basic optional primary sale fee incentive mechanism in Press.sol?
    Completely optional, but allows front end create services to set themselves an immutable fee
    upon contract deploy that gets paid out permissionlessly on withdraw

#### REMAINING EDITS
1. Redo factory + factory proxy impls
2. Press.sol -- clean up upgradeablility + proxy inits
3. Press.sol -- Determine if need to add in any missing erc721 util functionality
4. Press.sol -- add ability to withdraw non ETH funds
    -- does contract need FundsReciever import?  
5. DefaultLogic.sol -- UPDATE ACCESS CONTROL TO ENUM BASED +  update isAdmin/Editor checks in address(this) + ArtifactRenderer + Press.sol?
6. DefaultLogic.sol - Move maxSupply into Press.sol to prevent issues if a Press swithes logic impls? 
    -- thought comes from https://metalabel.notion.site/040-Metalabel-Protocol-Walkthrough-64e892c31f6a4090a2c92088300b62c4
    -- maybe allow a configurable "hardcap" on the collection size, and configurable "softcap" on the Logic side
7. FIX ALL THE EVENTS + ERRORS + VARIABLES + FUNCTION NAMES + NATSPEC AHHHHH
8. Tests
9. Deploy scripts

### Local Development

1. `git clone https://github.com/public-assembly/onchain-modules.git`
2. cd into cloned folder
3. install [Foundry](https://github.com/foundry-rs/foundry)
4. `foundryup`
5. `forge install`
6. `forge test` to contents have been installed correctly (tests should pass)
