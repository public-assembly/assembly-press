import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface OverwriteProps {
  database: Hex
  target: Hex
  tokenIds: bigint[]
  data: Hash[]
  prepareTxn: boolean
}

interface OverwriteReturn {
  overwriteConfig: PrepareWriteContractResult
  overwrite: (() => void) | undefined
  overwriteLoading: boolean
  overwriteSuccess: boolean
}

export function useOverwrite({
  database,
  target,
  tokenIds,
  data,
  prepareTxn
}: OverwriteProps): OverwriteReturn {
  const { config: overwriteConfig } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'overwrite',
    args: [target, tokenIds, data],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: overwriteData, write: overwrite } = useContractWrite(overwriteConfig)

  const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } =
    useWaitForTransaction({
      hash: overwriteData?.hash,
    })

  return {
    overwriteConfig,
    overwrite,
    overwriteLoading,
    overwriteSuccess,
  }
}
