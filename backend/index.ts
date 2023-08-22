import { backfillPostgres } from './backfill'
import { watchRouterEvents } from './watch/watchRouterEvents'
import {bundlrUpload} from './bundlr/bundlrUpload'
import cron from "node-cron";

async function main() {
  await backfillPostgres()
  watchRouterEvents() 
}
main()
cron.schedule(
  "35 15 * * *",
  () => {
    console.log("Uploading data to Arweave at 15:35 EST");
    bundlrUpload();
  },
  {
    scheduled: true,
    timezone: "America/New_York",
  }
);
