import { backfillPostgres } from './backfill'
import { blockCrawl } from './blockCrawl'

async function main() {
  await backfillPostgres()
  blockCrawl()
}

main()
