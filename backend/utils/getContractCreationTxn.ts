import fetch from 'node-fetch'

export async function getContractCreationTxn(etherscanApiUrl: string) {
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
