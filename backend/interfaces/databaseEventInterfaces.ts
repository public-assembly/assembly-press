import { type Hex } from 'viem';

export interface FactoryRegistered {
  transactionHash: Hex | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    factories: Hex[];
    statuses: boolean[];
  };
  eventName: 'FactoryRegistered';
}
export interface PressRegistered {
  transactionHash: Hex | null;
  blockNumber: bigint | null;

  args: {
    sender: Hex;
    factory: Hex;
    newPress: Hex;
  };
  eventName: 'PressRegistered';
}

export interface TokenDataStored {
  transactionHash: Hex | null;
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
  transactionHash: Hex | null;
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
  transactionHash: Hex | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    tokenIds: bigint[];
  };
  eventName: 'TokenDataRemoved';
}

export interface PressDataUpdated {
  transactionHash: Hex | null;
  blockNumber: bigint | null;
  args: {
    sender: Hex;
    press: Hex;
    pointer: Hex;
  };
  eventName: 'PressDataUpdated';
}
