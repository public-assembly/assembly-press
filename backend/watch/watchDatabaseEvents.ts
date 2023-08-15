import { parseAbi, type Hex } from 'viem'
import { decodeLogs } from '../transform/decodeLogs'
import { viemClient } from '../viem/client'
import { databaseAbiEventsArray } from '../constants/events'
import { writeToDatabase } from '../prisma'


export const watchDatabaseEvents = () => {
    const parsedEvent = parseAbi(databaseAbiEventsArray)
    viemClient.watchEvent({
      address: process.env.DATABASE_ADDRESS as Hex,
      events: parsedEvent,
      onLogs: (logs) => {
        writeToDatabase(decodeLogs(logs))
      }
    })
  }
