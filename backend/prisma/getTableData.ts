import { prismaClient } from './prismaClient'

export const getTableData = async () => {
  const rawTransactionData = await prismaClient.rawTransaction.findMany()
  const tokenStorageData = await prismaClient.tokenStorage.findMany()
  const AP721Data = await prismaClient.aP721.findMany()

  if (
   rawTransactionData.length === 0 &&
    tokenStorageData.length === 0 &&
    AP721Data.length === 0
  ) {
    return null
  }

  return { rawTransactionData, tokenStorageData, AP721Data }
}
