## Protocol Developmenet Status
ERC721 Architecture - First draft complete

Note: an older [branch](https://github.com/public-assembly/assembly-press/tree/0xTranqui/Full-Rewrite-230615) with a slightly different design was further along, and offers helpful insight into how we are thinking of `logic` + `renderer` contracts, as well as the role of `strategies`

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
