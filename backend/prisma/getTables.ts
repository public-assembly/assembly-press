import { prismaClient } from './prismaClient'

export const getTableData = async () => {
  const transactionData = await prismaClient.transaction.findMany()
  const tokenStorageData = await prismaClient.tokenStorage.findMany()
  const AP721Data = await prismaClient.aP721.findMany()

  // console.log(transactionData,tokenStorageData,AP721Data)

  return { transactionData, tokenStorageData, AP721Data }
}