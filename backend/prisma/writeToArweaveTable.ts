import { UploadResponse } from '@bundlr-network/client/build/cjs/common/types'
import { prismaClient } from './prismaClient'
import { Prisma } from '@prisma/client'

export const writeToArweaveTable = async (
  tableName: string,
  uploadResult: UploadResponse,
) => {
  console.log(tableName, uploadResult)
  console.log(
    `writeToArweaveTable called with tableName: ${tableName} and uploadResult: ${JSON.stringify(
      uploadResult,
    )}`,
  )
  const link = `https://arweave.net/${uploadResult.id}`
  try {
    switch (tableName) {
      case 'rawTransaction': {
        const dataTransaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        }
        await prismaClient.arweave.create({ data: dataTransaction })
        break
      }
      case 'tokenStorage': {
        const dataTokenTransaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        }

        await prismaClient.arweave.create({ data: dataTokenTransaction })
        break
      }
      case 'router': {
        const dataRouterTransaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        }

        await prismaClient.arweave.create({ data: dataRouterTransaction })
        break
      }
      default:
        throw new Error(`Invalid table name: ${tableName}`)
    }
  } catch (error) {
    console.error('Error saving links to Arweave table:', error)
  }
}
