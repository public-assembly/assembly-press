import { parseAbi, type Hex } from 'viem'
import { decodeLogs } from '../transform/decodeLogs'
import { viemClient } from '../viem/client'
import { routerAbiEventsArray } from '../constants'
import { writeToDatabase } from '../prisma'

export const watchDatabaseEvents = () => {
    const parsedEvent = parseAbi(routerAbiEventsArray)
    viemClient.watchEvent({
      address: process.env.ROUTER_ADDRESS as Hex,
      events: parsedEvent,
      onLogs: (logs) => {
        writeToDatabase(decodeLogs(logs))
      }
    })
  }
