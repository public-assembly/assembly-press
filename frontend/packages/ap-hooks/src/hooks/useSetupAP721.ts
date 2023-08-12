import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
// import { PrepareWriteContractResult }from 'wagmi'
import { UsePrepareContractWriteConfig } from 'wagmi'
import { AP721DatabaseV1Abi } from '../contracts'
import { optimismGoerli } from 'wagmi/chains'
import { Hex, Hash } from 'viem'

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

import {
  prepareWriteContract,
  writeContract,
  PrepareWriteContractResult,
} from 'wagmi/actions'

// const { request } = await prepareWriteContract({
//   address: '0xecb504d39723b0be0e3a9aa33d646642d1051ee1',
//   abi: wagmigotchiABI,
//   functionName: 'feed',
// })
// const { hash } = await writeContract(request)

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
