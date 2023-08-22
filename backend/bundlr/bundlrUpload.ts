import { getBalance } from "./utils";
import { uploadTableDataToBundlr } from "./uploadTableDataToBundlr";
import { writeToArweaveTable } from "../prisma/writeToArweaveTable";


export async function bundlrUpload() {
  await getBalance();

  const uploadData = await uploadTableDataToBundlr();

  if (uploadData === null) {
    return;
  }

  const { rawTransactionUpload, tokenStorageUpload, RouterUpload } = uploadData;

  await writeToArweaveTable("rawTransaction", rawTransactionUpload);
  console.log("saveLinksToArweaveTable for rawTransaction done");
  await writeToArweaveTable("tokenStorage", tokenStorageUpload);
  console.log("saveLinksToArweaveTable for tokenStorage done");
  await writeToArweaveTable("router", RouterUpload);
  console.log("saveLinksToArweaveTable for router done");
}
