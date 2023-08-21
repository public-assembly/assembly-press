import { type Log, decodeEventLog } from 'viem';
import { routerAbi } from '../abi';
import {
  FactoryRegistered,
  PressRegistered,
  TokenDataStored,
  TokenDataOverwritten,
  TokenDataRemoved,
  PressDataUpdated,
} from '../interfaces';

type DecodeLogsReturn =
  | FactoryRegistered
  | PressRegistered
  | TokenDataStored
  | TokenDataOverwritten
  | TokenDataRemoved
  | PressDataUpdated;

// Decodes ABI encoded event topics & data into an event name, block number and structured arguments
export function decodeLogs(logs: Log[]): DecodeLogsReturn[] {
  const decodedLogs = logs.map((log) => {
    const decodedLog = decodeEventLog({ ...log, abi: routerAbi });
    return {
      ...decodedLog,
      transactionHash: log.transactionHash,
      blockNumber: log.blockNumber,
    };
  });

  return decodedLogs;
}
