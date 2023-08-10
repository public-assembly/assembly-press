import { getBalance } from "./utils";
import { uploadTableDataToBundlr } from "./uploadTableDataToBundlr";
import { writeToArweaveTable } from "../prisma/writeToArweaveTable";


export async function bundlrUpload() {
  await getBalance();

  const uploadData = await uploadTableDataToBundlr();

  if (uploadData === null) {
    return;
  }

  const { rawTransactionUpload, tokenStorageUpload, AP721Upload } = uploadData;

  await writeToArweaveTable("rawTransaction", rawTransactionUpload);
  console.log("saveLinksToArweaveTable for rawTransaction done");
  await writeToArweaveTable("tokenStorage", tokenStorageUpload);
  console.log("saveLinksToArweaveTable for tokenStorage done");
  await writeToArweaveTable("AP721", AP721Upload);
  console.log("saveLinksToArweaveTable for AP721 done");
}

bundlrUpload();