import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface StoreProps {
  database: Hex
  target: Hex
  quantity: bigint
  data: Hash
  prepareTxn: boolean
}

interface StoreReturn {
  storeConfig: PrepareWriteContractResult
  store: (() => void) | undefined
  storeLoading: boolean
  storeSuccess: boolean
}

export function useStore({ database, target, quantity, data, prepareTxn }: StoreProps): StoreReturn {
  const { config: storeConfig } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'store',
    args: [target, quantity, data],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: storeData, write: store } = useContractWrite(storeConfig)

  const { isLoading: storeLoading, isSuccess: storeSuccess } =
    useWaitForTransaction({
      hash: storeData?.hash,
    })

  return {
    storeConfig,
    store,
    storeLoading,
    storeSuccess,
  }
}
