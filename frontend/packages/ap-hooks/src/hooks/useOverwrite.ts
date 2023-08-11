import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { AP721DatabaseV1Abi } from '../contracts'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'

interface OverwriteProps {
  database: Hex
  target: Hex
  tokenIds: bigint[]
  data: Hash[]
  prepareTxn: boolean
}

export function useOverwrite({
  database,
  target,
  tokenIds,
  data,
  prepareTxn
}: OverwriteProps) {
  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'overwrite',
    args: [target, tokenIds, data],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: overwriteData, write: overwrite } = useContractWrite(config)

  const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } =
    useWaitForTransaction({
      hash: overwriteData?.hash,
    })

  return {
    // config,
    overwrite,
    overwriteLoading,
    overwriteSuccess,
  }
}
