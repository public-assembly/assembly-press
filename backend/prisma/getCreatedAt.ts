import { prisma } from './prismaClient'

export async function getCreatedAt() {
    
  const genesisEntry = await prisma.transaction.findMany()

  return genesisEntry
}
