import { prismaClient } from './prismaClient'

export async function getTransactions() {
  const transactions = await prismaClient.transaction.findMany()
  return transactions
}
