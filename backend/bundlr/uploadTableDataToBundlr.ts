import { replacer } from '../utils'
import { bundlr } from './bundlrInit'
import { createBundlrTags } from './createBundlrTags'
import { getTableData } from '../prisma/getTableData'

export const uploadTableDataToBundlr = async () => {
  const tableData = await getTableData()

  if (tableData === null) {
    console.log('Tables are empty. Stopping the script for today.')
    return null
  }

  /**
   * Handle Transaction snapshot
   * 1. Attach the `transaction` identifier to this group of logs
   * 2. Parse any JSON data including bigints
   * 3. Get the size of the upload
   * 4. Given the size, get the cost of the upload
   * 5. Fund the Bundlr node with the appropriate amount
   * 6. Upload the data to Arweave and return the transaction id
   **/
  const rawTransactionTags = createBundlrTags('rawTransaction')

  const rawTransactionDataStr = JSON.stringify(
    tableData.rawTransactionData,
    replacer,
    2,
  )
  const rawTransactionDataSize = Buffer.byteLength(rawTransactionDataStr, 'utf8')

  const rawTransactionPrice = await bundlr.getPrice(rawTransactionDataSize)

  await bundlr.fund(rawTransactionPrice)

  const rawTransactionUpload = await bundlr.upload(rawTransactionDataStr, {
    tags: rawTransactionTags,
  })
  console.log(
    `Transaction data --> Uploaded to https://arweave.net/${rawTransactionUpload.id}`,
  )

  /**
   * Handle Token Storage snapshot
   * 1. Attach the `tokenStorage` identifier to this group of logs
   * 2. Parse any JSON data including bigints
   * 3. Get the size of the upload
   * 4. Given the size, get the cost of the upload
   * 5. Fund the Bundlr node with the appropriate amount
   * 6. Upload the data to Arweave and return the transaction id
   **/
  const tokenStorageTags = createBundlrTags('tokenStorage')

  const tokenStorageDataStr = JSON.stringify(
    tableData.tokenStorageData,
    replacer,
    2,
  )
  const tokenStorageDataSize = Buffer.byteLength(tokenStorageDataStr, 'utf8')

  const tokenStoragePrice = await bundlr.getPrice(tokenStorageDataSize)

  await bundlr.fund(tokenStoragePrice)

  const tokenStorageUpload = await bundlr.upload(
    JSON.stringify(tableData.tokenStorageData, replacer, 2),
    { tags: tokenStorageTags },
  )
  console.log(
    `Token Storage data --> Uploaded to https://arweave.net/${tokenStorageUpload.id}`,
  )

  /**
   * Handle RouterV1 snapshot
   * 1. Attach the `RouterV1` identifier to this group of logs
   * 2. Parse any JSON data including bigints
   * 3. Get the size of the upload
   * 4. Given the size, get the cost of the upload
   * 5. Fund the Bundlr node with the appropriate amount
   * 6. Upload the data to Arweave and return the transaction id
   **/
  const RouterV1Tags = createBundlrTags('RouterV1')

  const RouterDataStr = JSON.stringify(tableData.RouterData, replacer, 2)

  const RouterDataSize = Buffer.byteLength(RouterDataStr, 'utf8')

  const RouterPrice = await bundlr.getPrice(RouterDataSize)

  await bundlr.fund(RouterPrice)

  const RouterUpload = await bundlr.upload(
    JSON.stringify(tableData.RouterData, replacer, 2),
    { tags: RouterV1Tags },
  )

  console.log(
    `RouterV1 data --> Uploaded to https://arweave.net/${RouterUpload.id}`,
  )

  return { rawTransactionUpload, tokenStorageUpload, RouterUpload }
}
