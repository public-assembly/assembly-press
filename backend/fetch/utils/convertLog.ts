import { Log } from 'viem'
import { convertArgs } from './convertArgs'
import { DatabaseLog } from '../../types'

// TODO: type the arguments as Log from viem, fix resulting errors
// rome-ignore lint: allow explicit any
export function convertLog(log: any): DatabaseLog {
  return {
    address: log.address,
    blockHash: log.blockHash,
    blockNumber: log.blockNumber,
    data: log.data,
    topics: log.topics,
    transactionHash: log.transactionHash,
    args: convertArgs(log.args as object), // Cast args to object
    eventName: log.eventName,
  }
}
