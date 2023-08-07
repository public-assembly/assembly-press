import { backfillPostgres } from './backfill'
import { watchDatabaseEvents } from './watch/watchDatabaseEvents'

async function main() {
  await backfillPostgres()
  watchDatabaseEvents()
}

main()
