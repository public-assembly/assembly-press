import { bundlr } from '../bundlrInit'

export async function getBalance() {
  console.log('Connected wallet address:', bundlr.address)
  const atomicBalance = await bundlr.getLoadedBalance()
  const convertedBalance = bundlr.utils.fromAtomic(atomicBalance).toString()
  console.log('Account balance:', convertedBalance)
}
