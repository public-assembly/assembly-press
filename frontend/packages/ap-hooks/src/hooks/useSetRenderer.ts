import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface SetRendererProps {
  database: Hex
  target: Hex
  renderer: Hex
  rendererInit: Hash
  prepareTxn: boolean
}

interface SetRendererReturn {
  setRendererConfig: PrepareWriteContractResult
  setRenderer: (() => void) | undefined
  setRendererLoading: boolean
  setRendererSuccess: boolean
}

export function useSetRenderer({
  database,
  target,
  renderer,
  rendererInit,
  prepareTxn,
}: SetRendererProps): SetRendererReturn {
  const { config: setRendererConfig } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setRenderer',
    args: [target, renderer, rendererInit],
    chainId: optimismGoerli.id,
    enabled: prepareTxn,
  })

  const { data: setRendererData, write: setRenderer } =
    useContractWrite(setRendererConfig)

  const { isLoading: setRendererLoading, isSuccess: setRendererSuccess } =
    useWaitForTransaction({
      hash: setRendererData?.hash,
    })

  return {
    setRendererConfig,
    setRenderer,
    setRendererLoading,
    setRendererSuccess,
  }
}
