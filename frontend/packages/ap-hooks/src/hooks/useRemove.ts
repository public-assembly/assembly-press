import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface RemoveProps {
  database: Hex
  target: Hex
  tokenIds: bigint[]
  prepareTxn: boolean
}

interface RemoveReturn {
  removeConfig: PrepareWriteContractResult
  remove: (() => void) | undefined
  removeLoading: boolean
  removeSuccess: boolean
}

export function useRemove({ database, target, tokenIds, prepareTxn }: RemoveProps): RemoveReturn {
  const { config: removeConfig } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'remove',
    args: [target, tokenIds],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: removeData, write: remove } = useContractWrite(removeConfig)

  const { isLoading: removeLoading, isSuccess: removeSuccess } =
    useWaitForTransaction({
      hash: removeData?.hash,
    })

  return {
    removeConfig,
    remove,
    removeLoading,
    removeSuccess,
  }
}
