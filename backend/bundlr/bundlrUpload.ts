import { getBalance } from "./utils";
import { uploadTableDataToBundlr } from "./uploadTableDataToBundlr";
import { writeToArweaveTable } from "../prisma/writeToArweaveTable";
import cron from "node-cron";

async function main() {
  await getBalance();

  const uploadData = await uploadTableDataToBundlr();

  if (uploadData === null) {
    return;
  }

  const { transactionUpload, tokenStorageUpload, AP721Upload } = uploadData;

  console.log("uploadTableDataToBundlr done");
  await writeToArweaveTable("transaction", transactionUpload);
  console.log("saveLinksToArweaveTable for transaction done");
  await writeToArweaveTable("tokenStorage", tokenStorageUpload);
  console.log("saveLinksToArweaveTable for tokenStorage done");
  await writeToArweaveTable("AP721", AP721Upload);
  console.log("saveLinksToArweaveTable for AP721 done");
}
cron.schedule(
  "0 0 * * *",
  () => {
    console.log("dumping at 12:00 at America/New_York timezone");
    main();
  },
  {
    scheduled: true,
    timezone: "America/New_York",
  }
);
