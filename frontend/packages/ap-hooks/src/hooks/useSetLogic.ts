import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { AP721DatabaseV1Abi } from '../contracts'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'

interface SetLogicProps {
  database: Hex
  target: Hex
  logic: Hex
  logicInit: Hash
}

export function useSetLogic({
  database,
  target,
  logic,
  logicInit,
}: SetLogicProps) {
  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setLogic',
    args: [target, logic, logicInit],
    chainId: optimismGoerli.id,
  })

  const { data: setLogicData, write: setLogic } = useContractWrite(config)

  const { isLoading: setLogicLoading, isSuccess: setLogicSuccess } =
    useWaitForTransaction({
      hash: setLogicData?.hash,
    })

  return {
    setLogic,
    setLogicLoading,
    setLogicSuccess,
  }
}
