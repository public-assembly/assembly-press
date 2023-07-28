import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { AP721DatabaseV1Abi } from '../contracts'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'

interface SetRendererProps {
  database: Hex
  target: Hex
  renderer: Hex
  rendererInit: Hash
}

export function useSetRenderer({
  database,
  target,
  renderer,
  rendererInit,
}: SetRendererProps) {
  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setRenderer',
    args: [target, renderer, rendererInit],
    chainId: optimismGoerli.id,
  })

  const { data: setRendererData, write: setRenderer } = useContractWrite(config)

  const { isLoading: setRendererLoading, isSuccess: setRendererSuccess } =
    useWaitForTransaction({
      hash: setRendererData?.hash,
    })

  return {
    setRenderer,
    setRendererLoading,
    setRendererSuccess,
  }
}
