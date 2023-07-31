import { DatabaseLog } from '../types'

export function cleanLog(log: DatabaseLog) {
  const {
    address = '0x0', // Default value
    blockNumber = BigInt(0),
    blockHash = '0x0', // Default value
    args = {},
    eventName,
    data = '0x0', // Default value
    transactionHash = '0x0', // Default value
    topics = [], // Default value
  } = log

  return {
    address,
    blockNumber,
    blockHash,
    args,
    eventName,
    data,
    transactionHash,
    topics,
  }
}
