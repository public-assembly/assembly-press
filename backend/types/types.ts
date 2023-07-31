import { type Abi, type Hex, type Log } from 'viem'

export type EventObject = {
  event: string
  abi: Abi
  address: Hex
}

type AdditionalProperties = {
  args?: {
    ap721?: string
    sender?: string
    initialOwner?: string
    logic?: string
    renderer?: string
    factory?: string
    target?: string
    tokenId?: bigint
    pointer?: string
  }
  eventName: string
}

export type DatabaseLog = Omit<Log, 'transactionIndex' | 'removed' | 'logIndex'> &
  AdditionalProperties
