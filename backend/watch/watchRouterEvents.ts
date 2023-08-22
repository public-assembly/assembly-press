import { parseAbi, type Hex } from 'viem';
import { decodeLogs } from '../transform/decodeLogs';
import { processLogs } from '../transform/processLogs';
import { viemClient } from '../viem/client';
import { routerAbiEventsArray } from '../constants';
import { writeToDatabase } from '../prisma';

export const watchRouterEvents = () => {
  const parsedEvent = parseAbi(routerAbiEventsArray);
  console.log('Watching router events...');
  viemClient.watchEvent({
    address: process.env.ROUTER_ADDRESS as Hex,
    events: parsedEvent,
    onLogs: async (logs) => {
      console.log(await processLogs(decodeLogs(logs)));
      const processedLogs = await processLogs(decodeLogs(logs));
      writeToDatabase(processedLogs);
    },
  });
};
