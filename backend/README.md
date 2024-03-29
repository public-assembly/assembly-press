## Overview

This repository contains an initial implementation of an indexer for Assembly Press protocol events. It provides backfilling + active event listening upon deployment, processing functions that convert Ethereum logs into useful data and stores them into PostgreSQL, and optional backups to Arweave of any of your PostgreSQL tables. The tables that are generated from the indexer can be accessed via a GraphQL endpoint.

## Notable Files

Here is a brief overview of the important files and their functions:

- `backfillPostgres.ts`: function retrieves the last block with an event and the current block number. Depending on whether an event has previously occurred, it fetches logs starting either from the block after the last event or from the contract's creation block, decodes these logs, and then writes the decoded logs to the database.
- `bundlrUpload.ts` : the script takes a "snapshot" of three database tables (`Raw Transaction`, `Token Storage`, and `Router`) and uploads to Arweave . This upload operation is scheduled daily at 15:35 EST via a cron job.
- `fetchLogs.ts`: given a range of blocks, generates filters for specific database events and retrieves the corresponding logs. It then sorts these logs based on block number and returns the sorted logs.
- `getContractCreationBlock.ts`: fetches the contract creation transaction from Etherscan and then retrieves the block number of that transaction. This block number indicates when the contract was created and serves as the starting point for `backfillPostgres.ts`.
- `getLastBlockWithEvents.ts`: retrieves the most recent events from the `Router` and `Token Storage` tables using the Prisma client. It returns the latest event's timestamp by comparing the `createdAt` of the Router table and the `updatedAt` of the `Token Storage` table. If there are no events in the Router table, it logs a message and ends execution.
- `getTableData.ts`: function fetches data from three tables (`Raw Transaction`, `Token Storage`, and `Router`) using the Prisma client. If all the tables are empty, it returns null; otherwise, it returns an object containing data from the three tables.
- `uploadTableDataToBundlr.ts`: fetches table data, checks if it's empty, and then processes and uploads three different sets of data (`Raw Transaction`, `Token Storage`, and `Router`) to Arweave by calculating the size and cost of each data upload, funding the Bundlr node accordingly, and then making the actual upload, finally logging the Arweave URLs for verification.
- `watchRouterEvents.ts`: sets up event listeners for specified Router events. When one of these events is detected, the function decodes the logs, processes them and writes the returned information to a relational database.
- `writeToArweaveTable.ts`: saves Arweave upload results to the database based on the specified table name (`Raw Transaction`, `Token Storage`, and `Router`). If an unrecognized table name is encountered, it throws an error.
- `writeToDatabase.ts`: processes an array of decoded logs. Based on the event name in each log (PressRegistered, TokenDataStored, TokenDataOverwritten, TokenDataRemoved, PressDataUpdated), it constructs the relevant database input and either creates or updates database records using Prisma. If an error is encountered while processing any log, the function logs the error and moves on to the next log.

## Local Development Prerequisites

Ensure you have Node.js installed. If not, download and install it from the official [Node.js website](https://nodejs.org/en/download/).

1. Setup your environment variables by creating a `.env` file at the root of your project. Refer to the `env.example` file for guidance on configuring environment variables.

You can change `FUNDING_ADDRESS` to any address and the script will be able to populate the event tables, but not the Transaction table. Refer to `prisma.schema` to see the Transaction table and other Event tables. Notice that Bundlr will only keep track of the transactions that were funded by the address corresponding to the private key you provided.

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
