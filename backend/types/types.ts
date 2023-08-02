import { type Abi, type Hex, type Log } from 'viem'
import {
  SetupAP721,
  RendererUpdated,
  LogicUpdated,
  DataStored,
  DataRemoved,
  DataOverwritten,
} from '../interfaces'

export type EventObject = {
  event: string
  abi: Abi
  address: Hex
}

export type DecodedLog =
  | SetupAP721
  | RendererUpdated
  | LogicUpdated
  | DataStored
  | DataRemoved
  | DataOverwritten

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

export type DatabaseLog = Omit<
  Log,
  'transactionIndex' | 'removed' | 'logIndex'
> &
  AdditionalProperties
