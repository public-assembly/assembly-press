import { type Log, decodeEventLog } from 'viem';
import { AP721DatabaseV1Abi } from '../abi';
import { DecodedLog } from '../types';

// Decodes ABI encoded event topics & data into an event name and structured arguments
// : DecodedLog[]
export function decodeLogs(logs: Log[]): DecodedLog[] {
  const decodedLogs = logs.map((log) => {
    const decodedLog = decodeEventLog({ ...log, abi: AP721DatabaseV1Abi });
    return { ...decodedLog, blockNumber: log.blockNumber };
  });

  console.log(decodedLogs);
  return decodedLogs;
}
