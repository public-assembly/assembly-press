import sdk from '../client'
import { BlockNumber } from 'viem'

export interface Transaction {
  createdAt: BlockNumber
  eventType: string
  transactionHash: string
}

export const recentTransactions = async (): Promise<
  Transaction[] | undefined
> => {
  const { Transaction } = await sdk.RecentTransactions()

  return Transaction
}
