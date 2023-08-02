import { getContractCreationBlock } from '../utils'
import { viemClient } from '../viem/client'
import { fetchLogs } from '.'
import { BlockNumber } from 'viem'
import { decodeLogs } from '../transform/decodeLogs'
import { writeToDatabase } from '../prisma'

export async function backfillPostgres() {
  const contractCreationBlock = await getContractCreationBlock()

  const currentBlock = await viemClient.getBlockNumber()

  const sortedLogs = await fetchLogs(
    contractCreationBlock as BlockNumber,
    currentBlock,
  )

  const decodedLogs = decodeLogs(sortedLogs)

  writeToDatabase(decodedLogs)
}

backfillPostgres()
