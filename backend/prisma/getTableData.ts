import { prismaClient } from './prismaClient'

export const getTableData = async () => {
  const rawTransactionData = await prismaClient.rawTransaction.findMany()
  const tokenStorageData = await prismaClient.tokenStorage.findMany()
  const RouterData = await prismaClient.router.findMany()

  if (
   rawTransactionData.length === 0 &&
    tokenStorageData.length === 0 &&
    RouterData.length === 0
  ) {
    return null
  }

  return { rawTransactionData, tokenStorageData, RouterData }
}
