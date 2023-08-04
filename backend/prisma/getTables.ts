import { prismaClient } from './prismaClient'

export const getTableData = async () => {
  const transactionData = await prismaClient.transaction.findMany();
  const tokenStorageData = await prismaClient.tokenStorage.findMany();
  const AP721Data = await prismaClient.aP721.findMany();

  if (transactionData.length === 0 && tokenStorageData.length === 0 && AP721Data.length === 0) {
    return null; 
  }

  return { transactionData, tokenStorageData, AP721Data };
};
