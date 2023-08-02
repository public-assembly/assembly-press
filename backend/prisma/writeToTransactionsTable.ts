import { prismaClient } from './prismaClient'

// TODO: configure this function to write to the `Transactions` database
async function writeToTransactionsDatabase() {
  // @ts-expect-error
  for (const transaction of processedTransactions) {
    if (transaction) {
      await prismaClient.transaction
        .create({
          data: {
            id: transaction.id,
            address: transaction.address,
            eventType: transaction.eventType,
            tags: transaction.tags,
          },
        })
        .catch((e: Error) =>
          console.error('Error upserting transaction:', e.message),
        )
    }
  }

  //   await processCleanedLogs(cleanedLogs);
  console.log('Finished processing cleaned logs')
}
