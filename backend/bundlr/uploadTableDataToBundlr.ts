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
  const transactionTags = createBundlrTags('transaction')

  const transactionDataStr = JSON.stringify(
    tableData.transactionData,
    replacer,
    2,
  )
  const transactionDataSize = Buffer.byteLength(transactionDataStr, 'utf8')

  const transactionPrice = await bundlr.getPrice(transactionDataSize)

  await bundlr.fund(transactionPrice)

  const transactionUpload = await bundlr.upload(transactionDataStr, {
    tags: transactionTags,
  })
  console.log(
    `Transaction data --> Uploaded to https://arweave.net/${transactionUpload.id}`,
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
   * Handle AP721 snapshot
   * 1. Attach the `AP721` identifier to this group of logs
   * 2. Parse any JSON data including bigints
   * 3. Get the size of the upload
   * 4. Given the size, get the cost of the upload
   * 5. Fund the Bundlr node with the appropriate amount
   * 6. Upload the data to Arweave and return the transaction id
   **/
  const AP721Tags = createBundlrTags('AP721')

  const AP721DataStr = JSON.stringify(tableData.AP721Data, replacer, 2)

  const AP721DataSize = Buffer.byteLength(AP721DataStr, 'utf8')

  const AP721Price = await bundlr.getPrice(AP721DataSize)

  await bundlr.fund(AP721Price)

  const AP721Upload = await bundlr.upload(
    JSON.stringify(tableData.AP721Data, replacer, 2),
    { tags: AP721Tags },
  )

  console.log(
    `AP721 data --> Uploaded to https://arweave.net/${AP721Upload.id}`,
  )

  return { transactionUpload, tokenStorageUpload, AP721Upload }
}
