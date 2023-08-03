import { prismaClient } from "./prismaClient";
import { Prisma } from "@prisma/client";


// Setup
export async function getLastTransaction() {
  // : Prisma.AP721Enumerable
  // const orderBylastTransaction = {
  //   updatedAt: { sort: 'asc', nulls: 'last' },
  // }

  // const whereLastTransaction: Prisma.AP721WhereInput = {
  //   createdAt: 12443140
  // }

  const transactions = await prismaClient.aP721.findMany({
    orderBy: {
      createdAt: "desc",
    },
    take: 1,
  });

  console.log(transactions)
  return transactions;
}

getLastTransaction()
