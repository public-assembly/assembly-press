import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from 'wagmi'
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

export function useSetupAP721({
  database,
  initialOwner,
  databaseInit,
  factory,
  factoryInit,
  prepareTxn
}: SetupAP721Props) {

  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: 'setupAP721',
    args: [initialOwner, databaseInit, factory, factoryInit],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  })

  const { data: setupAP721Data, write: setupAP721 } = useContractWrite(config)

  const { isLoading: setupAP721Loading, isSuccess: setupAP721Success } =
    useWaitForTransaction({
      hash: setupAP721Data?.hash,
    })

  return {
    // config,
    setupAP721,
    setupAP721Loading,
    setupAP721Success,
  }
}
