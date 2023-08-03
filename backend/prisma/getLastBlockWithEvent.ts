import { prismaClient } from './prismaClient'

export async function getLastBlockWithEvent() {
  const lastBlockAP721 = await prismaClient.aP721.findMany({
    orderBy: {
      createdAt: 'desc',
    },
    take: 1,
  })

  const lastBlockTokenStorage = await prismaClient.tokenStorage.findMany({
    orderBy: {
      updatedAt: 'desc',
    },
    take: 1,
  })

  let lastBlockWithEvent

  if (lastBlockAP721.length === 0) {
    console.log('No events are stored in the database')
    return
  } else if (lastBlockAP721.length > 0 && lastBlockTokenStorage.length > 0) {
    lastBlockWithEvent =
      lastBlockTokenStorage[0].updatedAt > lastBlockAP721[0].createdAt
        ? lastBlockTokenStorage[0].updatedAt
        : lastBlockAP721[0].createdAt
    return lastBlockWithEvent
  } else {
    lastBlockWithEvent = lastBlockAP721[0].createdAt
    return lastBlockWithEvent
  }
}
