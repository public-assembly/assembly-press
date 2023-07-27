import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { AP721DatabaseV1Abi } from '../contracts'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'

interface RemoveProps {
  database: Hex
  target: Hex
  tokenIds: bigint[]
}

export function useRemove({ database, target, tokenIds }: RemoveProps) {
  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'remove',
    args: [target, tokenIds],
    chainId: optimismGoerli.id,
  })

  const { data: removeData, write: remove } = useContractWrite(config)

  const { isLoading: removeLoading, isSuccess: removeSuccess } =
    useWaitForTransaction({
      hash: removeData?.hash,
    })

  return {
    remove,
    removeLoading,
    removeSuccess,
  }
}
