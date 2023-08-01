import { apolloClient } from '../apollo/apolloClient'
import { LAST_EVENT_QUERY } from '../gql'
import { getContractCreationTxn } from '.'
import { viemClient } from '../viem/client'
import fetch from 'cross-fetch'

export const getLastBlockNum = async () => {

  const etherscanApiUrl = `${process.env.ETHERSCAN_ENDPOINT}/api?module=contract&action=getcontractcreation&contractaddresses=${process.env.DATABASE_ADDRESS}&apikey=${process.env.ETHERSCAN_API_KEY}`

  if (!data.transactions.edges.length) {
    const txn = await getContractCreationTxn(etherscanApiUrl)
    const txnResult = txn?.result?.[0]
    if (!txnResult) {
      console.error(
        'No contract creation transaction found or an error occurred while fetching',
      )
      return
    }

    const { blockNumber } = await viemClient.getTransaction({ hash: txnResult.txHash })
    console.log(
      `Starting indexing when contract was created @ block number: ${blockNumber}`,
    )

    return blockNumber
  }

  const txnId = data.transactions.edges[0].node.id
  const [txnData] = await (await fetch(`https://arweave.net/${txnId}`)).json()

  console.log('Transaction data', txnData)
  
  return txnData?.blockNumber
}