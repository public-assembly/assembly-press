import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
import { PrepareWriteContractResult } from 'wagmi/actions'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'
import { AP721DatabaseV1Abi } from '../contracts'

interface SetupAP721Props {
  database: Hex
  initialOwner: Hex
  databaseInit: Hash
  factory: Hex
  factoryInit: Hash
  prepareTxn: boolean
}

interface SetupAP721Return {
  setupAP721Config: PrepareWriteContractResult
  setupAP721: (() => void) | undefined
  setupAP721Loading: boolean
  setupAP721Success: boolean
}

export function useSetupAP721({
  database,
  initialOwner,
  databaseInit,
  factory,
  factoryInit,
  prepareTxn,
}: SetupAP721Props): SetupAP721Return {
  const { config: setupAP721Config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setupAP721',
    args: [initialOwner, databaseInit, factory, factoryInit],
    chainId: optimismGoerli.id,
    enabled: prepareTxn,
  })

  const { data: setupAP721Data, write: setupAP721 } =
    useContractWrite(setupAP721Config)

  const { isLoading: setupAP721Loading, isSuccess: setupAP721Success } =
    useWaitForTransaction({
      hash: setupAP721Data?.hash,
    })

  return {
    setupAP721Config,
    setupAP721,
    setupAP721Loading,
    setupAP721Success,
  }
}
