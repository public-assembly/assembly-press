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
