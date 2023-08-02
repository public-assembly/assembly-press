import { viemClient } from '../viem/client'
import { type BlockNumber, type Hex } from 'viem'
import { AP721DatabaseV1Abi } from '../abi'
import { databaseEventsArray } from '../constants'

export const fetchLogs = async (
  fromBlock: BlockNumber,
  toBlock: BlockNumber,
) => {
  const filters = await Promise.all(
    databaseEventsArray.map((event) =>
      viemClient.createContractEventFilter({
        abi: AP721DatabaseV1Abi,
        address: process.env.DATABASE_CONTRACT as Hex,
        eventName: event,
        fromBlock: BigInt(fromBlock),
        toBlock: BigInt(toBlock),
      }),
    ),
  )

  console.log(
    `Filter created for blocks ${fromBlock} to ${toBlock}, getting logs...`,
  )

  const logPromises = filters.map((filter, index) =>
    viemClient.getFilterLogs({ filter: filter }).then((logs) =>
      logs.map((log) => ({
        ...log,
        eventName: databaseEventsArray[index],
      })),
    ),
  )

  const logs = await Promise.all(logPromises)

  const sortedLogs = logs
    .flat()
    .sort((a, b) => Number(a.blockNumber) - Number(b.blockNumber))

  return sortedLogs
}
