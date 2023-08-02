import { type Hex } from 'viem';

export interface SetupAP721 {
  blockNumber: bigint | null;
  eventName: 'SetupAP721';
  args: {
    ap721: Hex;
    sender: Hex;
    initialOwner: Hex;
    logic: Hex;
    renderer: Hex;
    factory: Hex;
  };
}

export interface RendererUpdated {
  blockNumber: bigint | null;
  args: {
    target: Hex;
    logic: Hex;
  };
  eventName: 'RendererUpdated';
}

export interface LogicUpdated {
  blockNumber: bigint | null;
  args: {
    target: Hex;
    logic: Hex;
  };
  eventName: 'LogicUpdated';
}

export interface DataStored {
  blockNumber: bigint | null;
  args: {
    target: Hex;
    sender: Hex;
    tokenId: bigint;
    pointer: Hex;
  };
  eventName: 'DataStored';
}
export interface DataRemoved {
  blockNumber: bigint | null;
  eventName: 'DataOverwritten';
  args: {
    target: Hex;
    sender: Hex;
    tokenId: bigint;
    pointer: Hex;
  };
}

export interface DataOverwritten {
  blockNumber: bigint | null;
  args: {
    target: Hex;
    sender: Hex;
    tokenId: bigint;
    pointer: Hex;
  };
  eventName: 'DataOverwritten';
}
