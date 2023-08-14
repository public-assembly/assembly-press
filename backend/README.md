## Overview

This repository contains an initial implementation of an indexer for Assembly Press protocol events. It provides backfilling + active event listening upon deployment, processing functions that convert ethereum logs into useful data and stores them into PostgreSQL, and optional backups to Arweave of any of your PostgreSQL tables. The tables that are generated from the indexer can be accessed via GraphQL endpoint.

## Notable files

Here is a brief overview of the important files and their functions:

- `backfillPostgrest.ts`: function retrieves the last block with an event and the current block number. Depending on whether an event has previously occurred, it fetches logs starting either from the block after the last event or from the contract's creation block, decodes these logs, and then writes the decoded logs to the database.
- `bundlrUpload.ts` : the script takes a "snapshot" of three database tables (transaction, tokenstorage, and AP721) and uploads to arweave . This upload operation is scheduled daily at 12:00 EST using node-cron.
- `fetchLogs.ts`: given a range of blocks, generates filters for specific database events and retrieves the corresponding logs from the Viem client. It then sorts these logs based on block numbers and returns the sorted logs.
- `getContractCreationBlock.ts`: fetches the contract creation transaction from Etherscan and then uses the viemClient to retrieve the block number of that transaction. This block number indicates when the contract was created on Optimism and servers as the starting point for `backfillPostgre.ts`.
- `getLastBlockWithEvents.ts`: retrieves the most recent events from the aP721 and tokenStorage tables using the Prisma client. It returns the latest event's timestamp by comparing the createdAt of the aP721 table and the updatedAt of the tokenStorage table. If there are no events in the aP721 table, it logs a message and ends execution.
- `getTableData.ts`: function fetches data from three tables (transaction, tokenStorage, and AP721) using the Prisma client. If all the tables are empty, it returns null; otherwise, it returns an object containing data from the three tables.
- `uploadTableDataToBundlr.ts`: fetches table data, checks if it's empty, and then processes and uploads three different sets of data (Transaction, Token Storage, AP721) to Arweave by calculating the size and cost of each data upload, funding the Bundlr node accordingly, and then making the actual upload, finally logging the Arweave URLs for verification.
- `watchDatabaseEvents.ts`: sets up event listeners for specified database ABI events. When one of these events is detected using the viemClient, the module decodes the logs and writes the decoded information to a database using Prisma.
- `writeToArweaveTable.ts`: saves Arweave upload results to the database based on the specified table name (transaction, tokenStorage, or AP721). If an unrecognized table name is encountered, it throws an error.
- `writeToDatabase.ts`: processes an array of decoded logs. Based on the event name in each log (SetupAP721, LogicUpdated, RendererUpdated, DataStored, DataOverwritten, or DataRemoved), it constructs the relevant database input and either creates or updates database records using Prisma. If an error is encountered while processing any log, the function logs the error and moves on to the next log.

## Local Development Prerequisites

Ensure you have Node.js installed. If not, download and install it from the official [Node.js website](https://nodejs.org/en/download/).

1. Setup your environment variables by creating a `.env` file at the root of your project. Refer to the `env.example` file for guidance on configuring environment variables.

```
PRIVATE_KEY='' (for funding Bundlr writes)
ALCHEMY_KEY=''
ETHERSCAN_API_KEY=''
FUNDING_ADDRESS=''
CONTRACT_ADDRESS=''
```

You can change `FUNDING_ADDRESS` to any address and the script will be able to populate the event tables, but not the Transaction table. Refer to `prisma.schema` to see Transaction table and other Event tables. Notice that Bundlr will only keep track of the transactions that were funded by the address corresponding to the private key you provided. \

`CONTRACT_ADDRESS` is the address of the contract you want to track. We're currently using `AP721DatabaseV1`. In theory you can use any address but you will have to adjust the event information and ABI accordingly.

2. Setup your database url in the following format:

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