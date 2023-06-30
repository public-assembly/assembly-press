# Assembly Press v4 Re-write

[Link](https://sepolia.etherscan.io/address/0x71b51f5d321bcf1441c49584a9373a0f6f10055f) to first Press created from new architecture

## Local Development

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
