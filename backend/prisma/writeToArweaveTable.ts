import { prismaClient } from "./prismaClient";
import { Prisma } from "@prisma/client";
export const saveLinksToArweaveTable = async (
  tableName: string,
  uploadResult: any
) => {
  console.log(tableName, uploadResult);
  console.log(
    `saveLinksToArweaveTable called with tableName: ${tableName} and uploadResult: ${JSON.stringify(
      uploadResult
    )}`
  );

  const link = `https://arweave.net/${uploadResult.id}`;
  try {
    switch (tableName) {
      case "transaction":
        const dataTransaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        };
        await prismaClient.arweave.create({ data: dataTransaction });
        break;
      case "tokenStorage":
        const dataTokenTransaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        };

        await prismaClient.arweave.create({ data: dataTokenTransaction });
        break;
      case "AP721":
        const dataAP721Transaction: Prisma.ArweaveCreateInput = {
          tableName: tableName,
          link: link,
        };

        await prismaClient.arweave.create({ data: dataAP721Transaction });
        break;
      default:
        throw new Error(`Invalid table name: ${tableName}`);
    }
  } catch (error) {
    console.error("Error saving links to Arweave table:", error);
  }
};
