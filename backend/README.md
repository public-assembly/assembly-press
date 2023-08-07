## Dreamweaver

Onchain event listener processing Assembly Press protocol events and posting them to Arweave.

## Prerequisites

Ensure you have Node.js installed. If not, download and install it from the official [Node.js website](https://nodejs.org/en/download/).

## Local Development

1. Clone the repo:

```
git clone [https://github.com/public-assembly/dreamweaver.git]
```

2. Navigate into the repository:

```
cd [your repository directory]
```

3. Install dependencies:

```
pnpm install
```

4. Setup your environment variables by creating a `.env` file at the root of your project. Refer to the `env.example` file for guidance on configuring environment variables.

PRIVATE_KEY='' (for funding Bundlr)

ALCHEMY_KEY=''
ETHERSCAN_API_KEY=''

#### You can change `FUNDING_ADDRESS` to any address and the script will be able to populate the event tables, but not the Transaction table. Refer to `prisma.schema` to see Transaction table and other Event tables. Notice that Bundlr will only keep track of the transactions that were funded by the address corresponding to the private key you provided.

FUNDING_ADDRESS=''

#### Address of the contract you want to track. We're currently using `ERC721_PRESS_FACTORY`. In theory you can use any address but you will have to adjust the event information and ABI accordingly.

CONTRACT_ADDRESS=''

5. Setup your database url in the following format:

```
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/DATABASE"
```

Replace `USER`, `PASSWORD`, and `DATABASE` with your PostgreSQL username, password, and database name, respectively.

## Running

to start indexer and check for events related from the given addresses:

`pnpm start`

some useful prisma commands:

`pnpm prisma migrate dev --name init`
`pnpm prisma migrate deploy`
`pnpm prisma generate`

## Files

Here is a brief overview of the important files and their functions:

- `addresses.ts`: contains a set of predefined addresses

- `apolloClient.ts` : instantiates an Apollo client

- `backfillPostgrest.ts`: function retrieves the last block with an event and the current block number. Depending on whether an event has previously occurred, it fetches logs starting either from the block after the last event or from the contract's creation block, decodes these logs, and then writes the decoded logs to the database.

- `bundlrInit.ts` : initializes a Bundlr client

- `bundlrUpload.ts` : the script takes a "snapshot" of three database tables (transaction, tokenstorage, and AP721) and uploads to arweave . This upload operation is scheduled daily at 12:00 EST using node-cron.

- `createBundlrTags.ts`: creates tags (name, value) so we can query bundlr for all events. passes custom chain and event info set in .env

- `decodeLogs.ts`: takes in an array of Ethereum logs and, using the ABI for the AP721DatabaseV1 smart contract, decodes them into a chosen format.

- `events.ts`: contains a set of predefined events that the application might use or trigger

- `fetchLogs.ts`: given a range of blocks, generates filters for specific database events and retrieves the corresponding logs from the Viem client. It then sorts these logs based on block numbers and returns the sorted logs.

- `getBalance.ts`: gets FUNDING_ADDRESS balance.

- `getContractCreationBlock.ts`: fetches the contract creation transaction from Etherscan and then uses the viemClient to retrieve the block number of that transaction. This block number indicates when the contract was created on Optimism and servers as the starting point for `backfillPostgre.ts`.

- `getLastBlockWithEvents.ts`: retrieves the most recent events from the aP721 and tokenStorage tables using the Prisma client. It returns the latest event's timestamp by comparing the createdAt of the aP721 table and the updatedAt of the tokenStorage table. If there are no events in the aP721 table, it logs a message and ends execution.

- `getTableData.ts`: function fetches data from three tables (transaction, tokenStorage, and AP721) using the Prisma client. If all the tables are empty, it returns null; otherwise, it returns an object containing data from the three tables.

- `index.ts`: ( in root folder ) initiates backfill and starts watching live blocks for events.

- `lastEvent.ts`: fetch details of the last event for a given funding address. The query filters transactions owned by the provided address and tags specific to the environment's chain ID and various database events, then orders the results in descending order to get the most recent event.

- `newTransaction`: query crafted to retrieve transaction details associated with a given funding address. The query selects transactions owned by the input address and filters them by specific tags relevant to the environment's chain ID and various database events. The results are ordered in ascending order.

- `replacer.ts`: a helper function that converts any bigint values to strings when working with JSONs

- `transactionInterfaces.ts` : defines the `Transaction` interface among others

- `types.ts`: defines the `EventObject`, `DatabaseEvents`, `DecodedLogs` and `AdditionalProperties`

- `uploadTableDataToBundlr.ts`: fetches table data, checks if it's empty, and then processes and uploads three different sets of data (Transaction, Token Storage, AP721) to Arweave by calculating the size and cost of each data upload, funding the Bundlr node accordingly, and then making the actual upload, finally logging the Arweave URLs for verification.

- `watchDatabaseEvents.ts`: sets up event listeners for specified database ABI events. When one of these events is detected using the viemClient, the module decodes the logs and writes the decoded information to a database using Prisma.

- `Viemclient.ts` : instantiates a viem client

- `writeToArweaveTable.ts`: saves Arweave upload results to the database based on the specified table name (transaction, tokenStorage, or AP721). If an unrecognized table name is encountered, it throws an error.

- `writeToDatabase.ts`: processes an array of decoded logs. Based on the event name in each log (SetupAP721, LogicUpdated, RendererUpdated, DataStored, DataOverwritten, or DataRemoved), it constructs the relevant database input and either creates or updates database records using Prisma. If an error is encountered while processing any log, the function logs the error and moves on to the next log.
