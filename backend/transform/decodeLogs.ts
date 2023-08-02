import { type Log, decodeEventLog } from 'viem';
import { AP721DatabaseV1Abi } from '../abi';

// Decodes ABI encoded event topics & data into an event name and structured arguments
export function decodeLogs(logs: Log[]) {
  const decodedLogs = logs.map((log) => {
    const decodedLog = decodeEventLog({ ...log, abi: AP721DatabaseV1Abi });
    return { ...decodedLog, blockNumber: log.blockNumber };
  });
  return decodedLogs;
}
