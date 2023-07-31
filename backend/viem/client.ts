import { createPublicClient, http } from 'viem'
import {
  mainnet,
  sepolia,
  optimism,
  optimismGoerli,
  zora,
  zoraTestnet,
} from 'viem/chains'

const transport = http(
  `${process.env.ALCHEMY_ENDPOINT}/v2/${process.env.ALCHEMY_KEY}`,
  {
    batch: {
      batchSize: 2000,
      wait: 2000,
    },
  },
)

const chainObject = {
  [mainnet.id]: mainnet,
  [sepolia.id]: sepolia,
  [optimism.id]: optimism,
  [optimismGoerli.id]: optimismGoerli,
  [zora.id]: zora,
  [zoraTestnet.id]: zoraTestnet,
  // Add other chains here...
}

export const viemClient = createPublicClient({
  // @ts-expect-error
  chain: chainObject[Number(process.env.CHAIN_ID)],
  transport,
})
