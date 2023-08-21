import { type Hex, type Hash } from 'viem';

export interface FactoryRegistered {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    factories: Hex[];
    statuses: boolean[];
  };
  eventName: 'FactoryRegistered';
}
export interface PressRegistered {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    factory: Hex;
    newPress: Hex;
  };
  eventName: 'PressRegistered';
}

export interface TokenDataStored {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    tokenIds: bigint[];
    pointers: Hex[];
  };
  eventName: 'TokenDataStored';
}

export interface TokenDataOverwritten {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    tokenIds: bigint[];
    pointers: Hex[];
  };
  eventName: 'TokenDataOverwritten';
}

export interface TokenDataRemoved {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    tokenIds: bigint[];
  };
  eventName: 'TokenDataRemoved';
}

export interface PressDataUpdated {
  transactionHash: Hash | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    pointer: Hex;
  };
  eventName: 'PressDataUpdated';
}
