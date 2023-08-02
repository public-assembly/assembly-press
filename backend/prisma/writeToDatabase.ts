import { prismaClient } from './prismaClient'
import { Prisma } from '@prisma/client'
import { DecodedLog } from '../types'

export const writeToDatabase = async (decodedLogs: DecodedLog[]) => {
  for (const log of decodedLogs) {
    try {
      switch (log.eventName) {
        case 'SetupAP721': {
          const dataAP721: Prisma.AP721CreateInput = {
            ap721: log.args.ap721,
            sender: log.args.sender,
            owner: log.args.initialOwner,
            logic: log.args.logic,
            renderer: log.args.renderer,
            factory: log.args.factory,
            createdAt: log.blockNumber as bigint,
          }
          await prismaClient.aP721.create({ data: dataAP721 })
          break
        }
        case 'LogicUpdated': {
          const dataLogicUpdated: Prisma.AP721UpdateInput = {
            logic: log.args.logic,
          }
          await prismaClient.aP721.update({
            where: { ap721: log.args.target },
            data: dataLogicUpdated,
          })
          break
        }
        case 'RendererUpdated': {
          const dataRendererUpdated: Prisma.AP721UpdateInput = {
            renderer: log.args.renderer,
          }
          await prismaClient.aP721.update({
            where: { ap721: log.args.target },
            data: dataRendererUpdated,
          })
          break
        }
        case 'DataStored': {
          const dataDataStored: Prisma.TokenStorageCreateInput = {
            ap721: log.args.target,
            tokenId: log.args.tokenId + BigInt(1),
            pointer: log.args.pointer,
            updatedAt: log.blockNumber as bigint,
            updatedBy: log.args.sender,
          }
          await prismaClient.tokenStorage.create({
            data: dataDataStored,
          })
          break
        }
        case 'DataOverwritten': {
          const whereDataOverwritten: Prisma.TokenStorageWhereUniqueInput = {
            ap721_tokenId: {
              ap721: log.args.target,
              tokenId: log.args.tokenId + BigInt(1),
            },
          }
          const dataDataOverwritten: Prisma.TokenStorageUpdateInput = {
            ap721: log.args.target,
            tokenId: log.args.tokenId + BigInt(1),
            pointer: log.args.pointer,
            updatedAt: log.blockNumber as bigint,
            updatedBy: log.args.sender,
          }
          await prismaClient.tokenStorage.update({
            where: whereDataOverwritten,
            data: dataDataOverwritten,
          })
          break
        }
        case 'DataRemoved': {
          const whereDataRemoved: Prisma.TokenStorageWhereUniqueInput = {
            ap721_tokenId: {
              ap721: log.args.target,
              tokenId: log.args.tokenId + BigInt(1),
            },
          }
          const dataDataRemoved: Prisma.TokenStorageUpdateInput = {
            ap721: log.args.target,
            tokenId: log.args.tokenId + BigInt(1),
            pointer: String(0x0000000000000000000000000000000000000000),
            updatedAt: log.blockNumber as bigint,
            updatedBy: log.args.sender,
          }
          await prismaClient.tokenStorage.update({
            where: whereDataRemoved,
            data: dataDataRemoved,
          })
          break
        }
      }
    } catch (e) {
      console.error(`Error processing event ${log.eventName}:`, e)
    }
  }
}
