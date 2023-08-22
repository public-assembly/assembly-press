import { prismaClient } from './prismaClient'

export async function getLastBlockWithEvent() {
  const lastBlockRouter = await prismaClient.press.findMany({
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

  if (lastBlockRouter.length === 0) {
    console.log('No events are stored in the database')
    return
  } else if (lastBlockRouter.length > 0 && lastBlockTokenStorage.length > 0) {
    lastBlockWithEvent =
      lastBlockTokenStorage[0].updatedAt > lastBlockRouter[0].createdAt
        ? lastBlockTokenStorage[0].updatedAt
        : lastBlockRouter[0].createdAt
    return lastBlockWithEvent
  } else {
    lastBlockWithEvent = lastBlockRouter[0].createdAt
    return lastBlockWithEvent
  }
}
