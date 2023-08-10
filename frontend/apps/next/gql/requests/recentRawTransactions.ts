import sdk from '../client'
import { BlockNumber } from 'viem'

export interface RawTransaction {
  createdAt: BlockNumber
  eventType: string
  transactionHash: string
}

export const recentRawTransactions = async (): Promise<
  RawTransaction[] | undefined
> => {
  const { RawTransaction: rawTransactions } = await sdk.RecentRawTransactions()

  return rawTransactions
}
