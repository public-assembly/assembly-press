import { prismaClient } from './prismaClient'
import { backfillPostgres } from '../backfill'

export async function getCreatedAt() {
  try {
    const genesisEntry = await prismaClient.aP721.findFirstOrThrow({
      select: {
        createdAt: true,
      },
    })

    console.log('Genesis entry:', Number(genesisEntry.createdAt))

    // TODO: does this return need to be a number or bigint?
    return genesisEntry.createdAt
  } catch (error) {
    backfillPostgres()
  }
}
