import { viemClient } from '../viem/client'
import { databaseEventObjects } from '../constants'
import { type BlockNumber } from 'viem'

export async function fetchLogs(fromBlock: BlockNumber, toBlock: BlockNumber) {
  const filters = await Promise.all(
    databaseEventObjects.map((eventObject) =>
      viemClient.createContractEventFilter({
        abi: eventObject.abi,
        address: eventObject.address,
        eventName: eventObject.event,
        fromBlock: BigInt(fromBlock),
        toBlock: BigInt(toBlock),
      }),
    ),
  )

  console.log(
    `Filter created for blocks ${fromBlock} to ${toBlock}, getting logs...`,
  )

  const logs = await Promise.all(
    filters.map((filter, index) =>
      viemClient.getFilterLogs({ filter: filter }).then((logs) =>
        logs.map((log) => ({
          ...log,
          eventName: databaseEventObjects[index].event,
        })),
      ),
    ),
  )

  return logs
}
