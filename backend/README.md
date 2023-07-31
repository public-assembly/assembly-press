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
# You can change `OWNER` to any address and the script will be able to populate the event tables, but not the Transaction table. Refer to `prisma.schema` to see Transaction table and other Event tables. Notice that Bundlr will only keep track of the transactions that were funded by the address corresponding to the private key you provided.
OWNER='' 
# Address of the contract you want to track. We're currently using `ERC721_PRESS_FACTORY`. In theory you can use any address but you will have to adjust the event information and ABI accordingly.
CONTRACT_ADDRESS=''


5. Setup your database url in the following format:

```
DATABASE_URL="postgresql://USER:PASSWORD@localhost:5432/DATABASE"
```

Replace `USER`, `PASSWORD`, and `DATABASE` with your PostgreSQL username, password, and database name, respectively.

## Running

to start indexer and check for events related from the given addresses:

pnpm ts-node processAndUpload.ts

some useful prisma commands:

npx prisma generate -- schema== prisma/schema.prisma
npx prisma migrate dev --name init
npx prisma migrate deploy

## Files

Here is a brief overview of the important files and their functions:

- `processAndUpload.ts`: this is the main script of the application. It connects to a wallet, fetches the account balance, retrieves events, and processes new events from the Assembly Press protocol, and finally stores the results in a database via Prisma. It shapes the data according to each event type and creates or updates records in the database. If a record exists, it updates it, otherwise, it creates a new one.

- `bundlrInit.ts` : initializes a Bundlr client

- `bundlrAction.ts`: handles Bundlr related actions: initializing Bundlr and Apollo client, creating metadata for Bundlr uploads, uploading logs to Arweave, fetching the last block from the last event in a transaction hash ID, and uploading log objects.

- `schema.prisma`: contains the database schema for the Prisma client. It describes the `User` and `Transaction` models.

- `fetchEvents.ts`: fetches logs for specific events occurring in Ethereum smart contracts, such as `CREATE_PRESS` and `DATA_STORED`, using viem. It retrieves the logs within a certain block range and uploads the logs to Arweave.

- `getEvents.ts`: fetches events from Ethereum. It uses a list of event objects, each with its respective ABI and address, to fetch logs from the Ethereum blockchain. It first retrieves the current block number and the last block where an event was found. It then fetches logs in chunks of 10,000 blocks (adjustable), starting from the last block where an event was found to the current block. If no logs are found, it returns an empty JSON object. If logs are found, they are added to an array of all logs, converted to a JSON string, and then uploaded to Arweave.

- `client.ts` : instantiates a viem client

- `apolloClient.ts` : instantiates an Apollo client

- `events.ts`: contains a set of predefined events that the application might use or trigger

- `addresses.ts`: contains a set of predefined addresses

- `replacer.ts`: a helper function that converts any bigint values to strings when working with JSONs

- `newTransaction.ts`: a GraphQL query for returning a set of event tags made by a given owner

- `types.ts`: defines the `EventObject` type

- `transactionInterfaces.ts` : defines the `Transaction` interface among others
