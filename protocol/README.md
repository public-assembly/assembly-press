## Protocol Development Status
Router Based Architecture - DRAFT

Note: an older [branch](https://github.com/public-assembly/assembly-press/tree/300f1ea78acf1e77823f476fdb2a7c519f5e8495/protocol/) with a slightly different design was further along, and offers helpful insight into how we are thinking of singleton database design, `logic` + `renderer` contracts, and `multiTarget` functions. Also included a much more robust test suite, which the newer design will replicate.

## Protocol Local Development

### Prerequisites
Ensure [Foundry](https://github.com/foundry-rs/foundry) is installed. Run the command `foundryup` to make sure it is up to date.

### Installation

Clone the repo and navigate to the directory. Install the project's dependencies with the following command:
```
$ forge install
```

Configure the environment variables necesary to run the test suite. `RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_KEY` should be supplied. DOUBLE CHECK git.ignore is ignoring .env at root level of assembly-press monorepo !!!

Next, run the test suite with the following command:
```
$ forge test
```
All tests should pass.
