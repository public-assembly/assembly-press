import { parseAbi, type Hex } from 'viem'
import { decodeLogs } from '../transform/decodeLogs'
import { viemClient } from '../viem/client'
import { routerAbiEventsArray } from '../constants'
import { writeToDatabase } from '../prisma'

export const watchRouterEvents = () => {
    const parsedEvent = parseAbi(routerAbiEventsArray)
    console.log('Watching router events...')
    viemClient.watchEvent({
      address: process.env.ROUTER_ADDRESS as Hex,
      events: parsedEvent,
      onLogs: (logs) => {
        console.log(decodeLogs(logs))
        // writeToDatabase(decodeLogs(logs))
      }
    })
  }
