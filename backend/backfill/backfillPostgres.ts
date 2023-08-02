import { getContractCreationBlock } from '../utils';
import { viemClient } from '../viem/client';
import { fetchLogs } from '.';
import { BlockNumber } from 'viem';
import { decodeLogs } from '../transform/decodeLogs';

export async function backfillPostgres() {
  const contractCreationBlock = await getContractCreationBlock();

  const currentBlock = await viemClient.getBlockNumber();

  const logs = await fetchLogs(
    contractCreationBlock as BlockNumber,
    currentBlock
  );

  decodeLogs(logs.flat());

  // upload logs here
}

backfillPostgres();
