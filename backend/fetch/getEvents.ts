import { fetchLogs } from './fetchLogs'
import { availableEventObjects, convertLog } from './utils'
import { getLastBlockNum } from '../utils'
import { processCleanedLogs } from '../processAndUpload'
import { viemClient } from '../viem/client'
import { uploadLogs } from '../bundlr'

export async function getEvents() {
  console.log('Fetching events...')

  const currentBlock = await viemClient.getBlockNumber()
  console.log(`Current block number is ${currentBlock}`)

  let fromBlock = await getLastBlockNum()

  const fetchPromises = []

  while (fromBlock <= currentBlock) {
    console.log('From block: ', BigInt(fromBlock))
    const toBlock: bigint =
      fromBlock + BigInt(10000) > currentBlock
        ? currentBlock
        : fromBlock + BigInt(10000)

    // push the fetchLogs promise into the array
    fetchPromises.push(fetchLogs(fromBlock, toBlock))

    fromBlock = toBlock + BigInt(1)
  }

  // wait for the fetch operations to complete and flatten the returned arrays into one
  const allLogs = (await Promise.all(fetchPromises)).flat()

  // sort allLogs
  allLogs.sort((a, b) => {
    if (a.blockNumber === null || b.blockNumber === null) {
      return 0
    }
    return Number(b.blockNumber) - Number(a.blockNumber)
  })

  const cleanedLogs = allLogs.map(convertLog)

  if (cleanedLogs.length === 0) {
    console.log('No logs to return.')
    return {
      cleanedLogs: [],
      logsJson: '{}',
      eventName: availableEventObjects[0].event,
    }
  }

  await processCleanedLogs(cleanedLogs)

  if (cleanedLogs.length > 0) {
    await uploadLogs(cleanedLogs)
  }

  return { cleanedLogs, eventName: availableEventObjects[0].event }
}
