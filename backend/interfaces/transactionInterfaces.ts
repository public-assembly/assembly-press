import { type Log, type Hex, type Hash } from 'viem'

export interface Tag {
  name: string
  value: string
}

export interface Node {
  id: string
  address: string
  tags: Tag[]
}

export interface Edge {
  node: Node
}

export interface Transactions {
  edges: Edge[]
}

export interface GraphQLResponse {
  transactions: Transactions
}



// export interface DatabaseLog extends Log {
//   address: Hex
//   blockHash: Hex
//   blockNumber: bigint
//   data: Hash
//   logIndex: number
//   transactionHash: Hash
//   transactionIndex: number
//   removed: boolean
//   topics: [] | [signature: Hash]
//   args?: {
//     ap721?: string
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
