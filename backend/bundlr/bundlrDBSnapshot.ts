import { replacer } from "../utils";
import { bundlr } from "./bundlrInit";
import { createBundlrTags } from "./createBundlrTags";
import { getTableData } from "../prisma/getTables";

export const uploadTableDataToBundlr = async () => {
  const tableData = await getTableData();

  // transaction tags
  const transactionTags = createBundlrTags("transaction");
  const tokenStorageTags = createBundlrTags("tokenStorage");
  const AP721Tags = createBundlrTags("AP721");

  // transaction table job 
  const transactionDataStr = JSON.stringify(
    tableData.transactionData,
    replacer,
    2
  );
  const transactionDataSize = Buffer.byteLength(transactionDataStr, "utf8");

  // Get the price for this size
  const transactionPrice = await bundlr.getPrice(transactionDataSize);
  console.log("Transaction Price:", transactionPrice);

  // Fund the price
  await bundlr.fund(transactionPrice);

  // Upload the transaction data
  const transactionUpload = await bundlr.upload(transactionDataStr, {
    tags: transactionTags,
  });
  console.log(
    `Transaction data --> Uploaded to https://arweave.net/${transactionUpload.id}`
  );

  // token storage job 
  const tokenStorageDataStr = JSON.stringify(
    tableData.tokenStorageData,
    replacer,
    2
  );
  const tokenStorageDataSize = Buffer.byteLength(tokenStorageDataStr, "utf8");

  // Get the price for this size
  const tokenStoragePrice = await bundlr.getPrice(tokenStorageDataSize);
  console.log("tokenStorage Price:", tokenStoragePrice);

  // Fund the price
  await bundlr.fund(tokenStoragePrice);

  const tokenStorageUpload = await bundlr.upload(
    JSON.stringify(tableData.tokenStorageData, replacer, 2),
    { tags: tokenStorageTags }
  );
  console.log(
    `Token Storage data --> Uploaded to https://arweave.net/${tokenStorageUpload.id}`
  );

  // ap721 job

  const AP721DataStr = JSON.stringify(tableData.AP721Data, replacer, 2);
  const AP721DataSize = Buffer.byteLength(AP721DataStr, "utf8");

  const AP721Price = await bundlr.getPrice(AP721DataSize);
  console.log("AP721 Price:", AP721Price);

  await bundlr.fund(AP721Price);

  const AP721Upload = await bundlr.upload(
    JSON.stringify(tableData.AP721Data, replacer, 2),
    { tags: AP721Tags }
  );

  console.log(
    `AP721 data --> Uploaded to https://arweave.net/${AP721Upload.id}`
  );

  return { transactionUpload, tokenStorageUpload, AP721Upload };
};
