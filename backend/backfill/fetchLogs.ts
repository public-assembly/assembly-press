import { viemClient } from '../viem/client'
import { type BlockNumber, type Hex } from 'viem'
import { routerAbi } from '../abi'
import { routerEventsArray } from '../constants'

export const fetchLogs = async (
  fromBlock: BlockNumber,
  toBlock: BlockNumber,
) => {
  const filters = await Promise.all(
    routerEventsArray.map((event) =>
      viemClient.createContractEventFilter({
        abi: routerAbi,
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
        eventName: routerEventsArray[index],
      })),
    ),
  )

  const logs = await Promise.all(logPromises)

  const sortedLogs = logs
    .flat()
    .sort((a, b) => Number(a.blockNumber) - Number(b.blockNumber))

  return sortedLogs
}
