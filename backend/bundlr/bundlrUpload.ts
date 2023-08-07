import { getBalance } from "./utils";
import { uploadTableDataToBundlr } from "./uploadTableDataToBundlr";
import { writeToArweaveTable } from "../prisma/writeToArweaveTable";
import cron from "node-cron";

async function bundlrUpload() {
  await getBalance();

  const uploadData = await uploadTableDataToBundlr();

  if (uploadData === null) {
    return;
  }

  const { transactionUpload, tokenStorageUpload, AP721Upload } = uploadData;

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
    console.log("Uploading data to Arweave at 12:00 EST");
    bundlrUpload();
  },
  {
    scheduled: true,
    timezone: "America/New_York",
  }
);
