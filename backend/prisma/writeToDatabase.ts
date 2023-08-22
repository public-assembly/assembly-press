import { prismaClient } from "./prismaClient";
import { Prisma } from "@prisma/client";
import { DecodedRouterEvent } from "../transform/decodeLogs";

export const writeToDatabase = async (decodedLogs: DecodedRouterEvent[]) => {
  for (const log of decodedLogs) {
    try {
      switch (log.eventName) {
        case "PressRegistered": {
          const dataPress: Prisma.PressCreateInput = {
            press: log.args.newPress,
            sender: log.args.sender,
            factory: log.args.factory,
            owner: String(0x0000000000000000000000000000000000000000),
            logic: log.additionalData[1],
            renderer: log.additionalData[2],
            fundsRecipient: log.additionalData[3].fundsRecipient,
            royaltyBPS: log.additionalData[3].royaltyBPS,
            transferable: log.additionalData[3].transferable,
            fungible: log.additionalData[3].fungible,
            createdAt: log.blockNumber as bigint,
            RawTransaction: {
              connectOrCreate: {
                where: { transactionHash: log.transactionHash as string },
                create: {
                  transactionHash: log.transactionHash as string,
                  createdAt: log.blockNumber as bigint,
                  eventType: log.eventName,
                },
              },
            },
          };
          await prismaClient.press.create({ data: dataPress });
          break;
        }
        case "TokenDataStored": {
          for (let i = 0; i < log.args.tokenIds.length; i++) {
            const dataDataStored: Prisma.TokenStorageCreateInput = {
              press: log.args.press,
              tokenId: log.args.tokenIds[i],
              pointer: log.args.pointers[i],
              updatedAt: log.blockNumber as bigint,
              updatedBy: log.args.sender,
              rawTransaction: {
                connectOrCreate: {
                  where: { transactionHash: log.transactionHash as string },
                  create: {
                    transactionHash: log.transactionHash as string,
                    createdAt: log.blockNumber as bigint,
                    eventType: log.eventName,
                  },
                },
              },
            };
            await prismaClient.tokenStorage.create({
              data: dataDataStored,
            });
          }
          break;
        }
        case "TokenDataOverwritten": {
          for (const [index, tokenId] of log.args.tokenIds.entries()) {
            const whereDataOverwritten: Prisma.TokenStorageWhereUniqueInput = {
              press_tokenId: {
                press: log.args.press,
                tokenId: tokenId,
              },
            };

            const dataDataOverwritten: Prisma.TokenStorageUpdateInput = {
              press: log.args.press,
              tokenId: tokenId,
              pointer: log.args.pointers[index],
              updatedAt: log.blockNumber as bigint,
              updatedBy: log.args.sender,
              rawTransaction: {
                connectOrCreate: {
                  where: { transactionHash: log.transactionHash as string },
                  create: {
                    transactionHash: log.transactionHash as string,
                    createdAt: log.blockNumber as bigint,
                    eventType: log.eventName,
                  },
                },
              },
            };
            await prismaClient.tokenStorage.update({
              where: whereDataOverwritten,
              data: dataDataOverwritten,
            });
          }

          break;
        }
        case "TokenDataRemoved": {
          for (const tokenId of log.args.tokenIds) {
            const whereDataRemoved: Prisma.TokenStorageWhereUniqueInput = {
              press_tokenId: {
                press: log.args.press,
                tokenId: tokenId,
              },
            };
            const dataDataRemoved: Prisma.TokenStorageUpdateInput = {
              press: log.args.press,
              tokenId: tokenId,
              pointer: String(0x0000000000000000000000000000000000000000),
              updatedAt: log.blockNumber as bigint,
              updatedBy: log.args.sender,
              rawTransaction: {
                connectOrCreate: {
                  where: { transactionHash: log.transactionHash as string },
                  create: {
                    transactionHash: log.transactionHash as string,
                    createdAt: log.blockNumber as bigint,
                    eventType: log.eventName,
                  },
                },
              },
            };
            await prismaClient.tokenStorage.update({
              where: whereDataRemoved,
              data: dataDataRemoved,
            });
          }
          break;
        }
      }
    } catch (e) {
      console.error(`Error processing event ${log.eventName}:`, e);
    }
  }
};
