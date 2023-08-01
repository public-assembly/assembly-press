import { getEvents } from './fetch/getEvents'
import { getBalance } from './bundlr/utils/getBalance'
import { getTransactions } from './prisma/getTransactions'
import { prisma } from './prisma/prismaClient'
import { Transactions, Node } from './interfaces/transactionInterfaces'
import { DatabaseLog } from './types'
import { apolloClient } from './apollo/apolloClient'
import { NEW_TRANSACTIONS_QUERY } from './gql'
import { schedule } from 'node-cron'

async function main() {
  await getBalance()
  await getTransactions()

  const result = await getEvents()
  const { cleanedLogs } = result

  const { data } = await apolloClient.query({
    query: NEW_TRANSACTIONS_QUERY,
    variables: { owner: process.env.OWNER },
  })

  const processedTransactions = processTransactions(data.transactions)

  for (const transaction of processedTransactions) {
    if (transaction) {
      await prisma.transaction
        .create({
          data: {
            id: transaction.id,
            address: transaction.address,
            eventType: transaction.eventType,
            tags: transaction.tags,
          },
        })
        .catch((e: Error) =>
          console.error('Error upserting transaction:', e.message),
        )
    }
  }

  await processCleanedLogs(cleanedLogs)
  console.log('Finished processing cleaned logs')
}

function processTransactions(transactions: Transactions) {
  const eventTypes = [
    'SetupAP721',
    'DataStored',
    'DataOverwritten',
    'DataRemoved',
    'LogicUpdated',
    'RendererUpdated',
  ]

  return transactions.edges.map((edge) => {
    const eventTag = edge.node.tags.find(
      (tag) =>
        tag.name === `Database Events - Chain: ${process.env.CHAIN_ID} v0.1`,
    )
    if (!eventTag || !eventTypes.includes(eventTag.value)) {
      return null
    }
    return shapeData(edge.node)
  })
}

function shapeData(node: Node) {
  const tags = node.tags.reduce((acc, tag) => {
    acc[tag.name] = tag.value
    return acc
  }, {} as Record<string, string>)

  return {
    id: node.id,
    address: node.address,
    eventType: tags[`Database Events - Chain: ${process.env.CHAIN_ID} v0.1`],
    tags,
  }
}

export async function processCleanedLogs(cleanedLogs: DatabaseLog[]) {
  for (const log of cleanedLogs) {
    if (!log.args) {
      console.log(`Skipping log due to missing args: ${JSON.stringify(log)}`)
      continue
    }
    console.log(`Processing log with event name: ${log.eventName}`)
    try {
      switch (log.eventName) {
        case 'SetupAP721':
          console.log('Checking conditions for SetupAP721...')
          if (
            log.args.ap721 &&
            log.args.sender &&
            log.args.initialOwner &&
            log.args.logic &&
            log.args.renderer &&
            log.args.factory !== undefined
          ) {
            console.log(
              'Conditions met for SetupAP721. Attempting to populate pressSettings table...',
            )

            await prisma.pressSettings.create({
              data: {
                sender: log.args.sender,
                initialOwner: log.args.initialOwner,
                logic: log.args.logic,
                renderer: log.args.renderer,
                factory: log.args.factory,
                eventType: log.eventName,
              },
            })
            console.log('Successfully populated pressSettings table.')
          } else {
            console.log(
              'Conditions for populating pressSettings table not met.',
            )
          }
          break
        case 'LogicUpdated':
          console.log('Checking conditions for LogicUpdated...')
          if (log.args.target && log.args.logic !== undefined) {
            console.log(
              'Conditions met for LogicUpdated. Attempting to update pressSettings table...',
            )

            await prisma.pressSettings.create({
              data: {
                logic: log.args.logic,
                target: log.args.target,
                eventType: log.eventName,
              },
            })
            console.log(
              'Successfully updated pressSettings table for LogicUpdated.',
            )
          } else {
            console.log(
              'Conditions for updating pressSettings table not met for LogicUpdated.',
            )
          }
          break
        case 'RendererUpdated':
          console.log('Checking conditions for RendererUpdated...')
          if (log.args.target && log.args.renderer !== undefined) {
            console.log(
              'Conditions met for RendererUpdated. Attempting to update pressSettings table...',
            )

            await prisma.pressSettings.create({
              data: {
                renderer: log.args.renderer,
                target: log.args.target,
                eventType: log.eventName,
              },
            })
            console.log(
              'Successfully updated pressSettings table for RendererUpdated.',
            )
          } else {
            console.log(
              'Conditions for updating pressSettings table not met for RendererUpdated.',
            )
          }
          break
        case 'DataStored':
        case 'DataOverwritten':
          console.log('Checking conditions for DataStored/DataOverwritten...')
          if (
            log.args.target &&
            log.args.sender &&
            log.args.tokenId &&
            log.args.pointer
          ) {
            console.log(
              'Conditions met for DataStored/DataOverwritten. Attempting to populate tokenStorage table...',
            )

            await prisma.tokenStorage.upsert({
              where: {
                target_sender_tokenId: {
                  target: log.args.target,
                  sender: log.args.sender,
                  tokenId: log.args.tokenId,
                },
              },
              update: {
                target: log.args.target,
                sender: log.args.sender,
                pointer: log.args.pointer,
                eventType: log.eventName,
              },
              create: {
                target: log.args.target,
                sender: log.args.sender,
                tokenId: log.args.tokenId,
                pointer: log.args.pointer,
                eventType: log.eventName,
              },
            })
            console.log('Successfully populated tokenStorage table.')
          } else {
            console.log('Conditions for populating tokenStorage table not met.')
          }
          break
        default:
          console.log(`Unknown event type: ${log.eventName}`)
      }
    } catch (e) {
      console.error(`Error processing event ${log.eventName}:`, e)
    }
  }
}

schedule('* * * * *', function () {
  main()
    .catch((e) => {
      console.error('Error running main: ', e)
      throw e
    })
    .finally(async () => {
      console.log('Finished all Prisma operations, disconnecting...')
      await prisma.$disconnect()
    })
})
