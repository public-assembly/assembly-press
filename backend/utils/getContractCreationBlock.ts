import fetch from 'cross-fetch'
import { viemClient } from '../viem/client'
import { etherscanApiUrl } from '../constants'
import { BlockNumber } from 'viem'

const getContractCreationTxn = async (etherscanApiUrl: string) => {
  try {
    const response = await fetch(etherscanApiUrl)
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }
    const data = await response.json()
    return data
  } catch (error) {
    console.error(
      'An error occurred while fetching contract creation transaction:',
      error,
    )
  }
}

export const getContractCreationBlock = async () => {
  const txn = await getContractCreationTxn(etherscanApiUrl)

  if (!txn) {
    console.error(
      'No contract creation transaction found, or an error occurred while fetching',
    )
    return
  }

  const txnHash = txn?.result[0].txHash

  const contractCreationTransaction = await viemClient.getTransaction({
    hash: txnHash,
  })

  const contractCreationBlock: BlockNumber =
    contractCreationTransaction.blockNumber

  console.log(
    `Begin indexing at contract creation block: ${contractCreationBlock}`,
  )

  return contractCreationBlock
}
