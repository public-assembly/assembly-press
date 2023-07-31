import { viemClient } from '../viem/client'
import { availableEventObjects } from './utils/availableEventObjects'

// fetch logs for given blocks and event objects
export async function fetchLogs(fromBlock: bigint, toBlock: bigint) {
  // create event filters for each eventObject
  const filters = await Promise.all(
    availableEventObjects.map((eventObject) =>
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
    `Filter created for block ${fromBlock} to ${toBlock}, getting logs...`,
  )

  // fetch logs for each filter
  const logs = await Promise.all(
    filters.map((filter, index) =>
      viemClient.getFilterLogs({ filter: filter }).then((logs) =>
        logs.map((log) => ({
          ...log,
          eventName: availableEventObjects[index].event,
        })),
      ),
    ),
  )

  // console.log("raw logs", logs)
  // console.log("raw logs", logs.flat())
  return logs.flat()
}
