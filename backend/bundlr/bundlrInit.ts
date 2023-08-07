import Bundlr from '@bundlr-network/client'

export const bundlr = new Bundlr(
  process.env.NODE_ENV === 'production'
    ? 'http://node1.bundlr.network'
    : 'http://devnet.bundlr.network',
  'ethereum',
  process.env.PRIVATE_KEY,
  {
    providerUrl: `${process.env.ALCHEMY_SEPOLIA_ENDPOINT}/v2/${process.env.ALCHEMY_KEY}`,
  },
)
