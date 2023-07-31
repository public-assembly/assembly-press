import { replacer } from '../utils'
import { bundlr } from './bundlrInit'
import { createBundlrTags } from './createBundlrTags'
import { DatabaseLog } from "../types"

export async function uploadLogs(logs: DatabaseLog[]) {
  const tags = createBundlrTags(logs)

  const response = await bundlr.upload(JSON.stringify(logs, replacer, 2), {
    tags,
  })

  console.log(`Uploaded logs: https://arweave.net/${response.id}`)

  return { response, cleanedLogs: logs }
}
