import { type Hex } from 'viem'

export interface SetupAP721 {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  eventName: 'SetupAP721'
  args: {
    ap721: Hex
    sender: Hex
    initialOwner: Hex
    logic: Hex
    renderer: Hex
    factory: Hex
  }
}

export interface RendererUpdated {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  args: {
    target: Hex
    renderer: Hex
  }
  eventName: 'RendererUpdated'
}

export interface LogicUpdated {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  args: {
    target: Hex
    logic: Hex
  }
  eventName: 'LogicUpdated'
}

export interface DataStored {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  args: {
    target: Hex
    sender: Hex
    tokenId: bigint
    pointer: Hex
  }
  eventName: 'DataStored'
}
export interface DataRemoved {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  args: {
    target: Hex
    sender: Hex
    tokenId: bigint
  }
  eventName: 'DataRemoved'
}

export interface DataOverwritten {
  transactionHash: Hex | null,
  blockNumber: bigint | null
  args: {
    target: Hex
    sender: Hex
    tokenId: bigint
    pointer: Hex
  }
  eventName: 'DataOverwritten'
}
