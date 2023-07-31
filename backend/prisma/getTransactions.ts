import { prisma } from './prismaClient'

export async function getTransactions() {
  const transactions = await prisma.transaction.findMany()
  return transactions
}
