import { type Log, decodeEventLog } from 'viem'
import { routerAbi } from '../abi'
import { DecodedLog } from '../types'

// Decodes ABI encoded event topics & data into an event name, block number and structured arguments
export function decodeLogs(logs: Log[]): DecodedLog[] {
  const decodedLogs = logs.map((log) => {
    const decodedLog = decodeEventLog({ ...log, abi: routerAbi })
    return {
      ...decodedLog,
      transactionHash: log.transactionHash,
      blockNumber: log.blockNumber,
    }
  })

  // @ts-expect-error
  return decodedLogs
}
