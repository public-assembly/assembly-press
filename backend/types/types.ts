import { type Abi, type Hex, type Log } from 'viem'
import {
  FactoryRegistered, PressRegistered, TokenDataStored, TokenDataOverwritten, TokenDataRemoved, PressDataUpdated
} from '../interfaces'

export type EventObject = {
  event: string
  abi: Abi
  address: Hex
}

export type RouterEvent =
  | 'FactoryRegistered'
  | 'PressRegistered'
  | 'TokenDataStored'
  | 'TokenDataOverwritten'
  | 'TokenDataRemoved'
  | 'PressDataUpdated'

export type DecodedLog =
  | FactoryRegistered
  | PressRegistered
  | TokenDataStored
  | TokenDataOverwritten
  | TokenDataRemoved
  | PressDataUpdated

// type AdditionalProperties = {
//   args?: {
//     router?: string
//     sender?: string
//     initialOwner?: string
//     logic?: string
//     renderer?: string
//     factory?: string
//     target?: string
//     tokenId?: bigint
//     pointer?: string
//   }
//   eventName: string
// }

// export type DatabaseLog = Omit<
//   Log,
//   'transactionIndex' | 'removed' | 'logIndex'
// > &
//   AdditionalProperties
