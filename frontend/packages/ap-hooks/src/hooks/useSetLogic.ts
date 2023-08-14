import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface SetLogicProps {
  database: Hex
  target: Hex
  logic: Hex
  logicInit: Hash
  prepareTxn: boolean
}

interface SetLogicReturn {
  setLogicConfig: PrepareWriteContractResult
  setLogic: (() => void) | undefined
  setLogicLoading: boolean
  setLogicSuccess: boolean
}

export function useSetLogic({
  database,
  target,
  logic,
  logicInit,
  prepareTxn
}: SetLogicProps): SetLogicReturn {
  const { config: setLogicConfig } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setLogic',
    args: [target, logic, logicInit],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: setLogicData, write: setLogic } = useContractWrite(setLogicConfig)

  const { isLoading: setLogicLoading, isSuccess: setLogicSuccess } =
    useWaitForTransaction({
      hash: setLogicData?.hash,
    })

  return {
    setLogicConfig,
    setLogic,
    setLogicLoading,
    setLogicSuccess,
  }
}
