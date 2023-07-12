## Protocol Developmenet Status
ERC721 - First draft complete \
ERC1155 - In-progress \
Curation - First draft complete \
Archive - In-progress \

## Protocol Local Development

### Prerequisites
Ensure [Foundry](https://github.com/foundry-rs/foundry) is installed. Run the command `foundryup` to make sure it is up to date.

### Installation

Clone the repo and navigate to the directory. Install the project's dependencies with the following command:
```
$ forge install
```

Configure the environment variables necesary to run the test suite. `SEPOLIA_RPC_URL`, `MAINNET_RPC_URL`, and `GOERLI_RPC_URL` should be supplied.

Next, run the test suite with the following command:
```
$ forge test
```
All tests should pass.
