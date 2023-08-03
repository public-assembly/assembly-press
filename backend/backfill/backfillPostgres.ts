import { getContractCreationBlock } from '../utils'
import { viemClient } from '../viem/client'
import { fetchLogs } from '.'
import { BlockNumber } from 'viem'
import { decodeLogs } from '../transform/decodeLogs'
import { writeToDatabase } from '../prisma'
import { getLastBlockWithEvent } from '../prisma'

export const backfillPostgres = async () => {
  const lastBlockWithEvent = await getLastBlockWithEvent()

  const currentBlock = await viemClient.getBlockNumber()

  if (lastBlockWithEvent) {
    const sortedLogs = await fetchLogs(
      lastBlockWithEvent as BlockNumber,
      currentBlock,
    )

    const decodedLogs = decodeLogs(sortedLogs)

    writeToDatabase(decodedLogs)
  } else {
    const contractCreationBlock = await getContractCreationBlock()

    const sortedLogs = await fetchLogs(
      contractCreationBlock as BlockNumber,
      currentBlock,
    )

    const decodedLogs = decodeLogs(sortedLogs)

    writeToDatabase(decodedLogs)
  }
}
