import { backfillPostgres } from './backfill'
import { watchRouterEvents } from './watch/watchRouterEvents'
import {bundlrUpload} from './bundlr/bundlrUpload'
import cron from "node-cron";

async function main() {
  // await backfillPostgres()
  watchRouterEvents()
  
}
main()
cron.schedule(
  "0 0 * * *",
  () => {
    console.log("Uploading data to Arweave at 12:00 EST");
    bundlrUpload();
  },
  {
    scheduled: true,
    timezone: "America/New_York",
  }
);
