import { DatabaseLog } from '../types'

// create metadata tags for Bundlr uploads that will help us identify our uploads later on
export const createBundlrTags = (logs: DatabaseLog[]) => {
  const tags = [{ name: 'Content-Type', value: 'application/json' }]

  // create a tag for each unique event name in the logs
  const uniqueEventNames = [...new Set(logs.map((log) => log.eventName))]
  uniqueEventNames.forEach((eventName) => {
    tags.push({
      name: `Database Events - Chain: ${process.env.CHAIN_ID} v0.1`,
      value: eventName,
    })
  })

  return tags
}
