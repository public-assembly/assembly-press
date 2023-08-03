import {
  createPublicClient,
  http,
  type Block,
  parseAbiItem,
  Abi,
  parseAbi,
  decodeDeployData,
} from "viem";
import { decodeLogs } from "./transform/decodeLogs";
import { viemClient } from "./viem/client";
import { databaseAbiEventsArray } from "./constants/events";
import { Hex } from "viem";

databaseAbiEventsArray.forEach((event: string) => {
  const parsedEvent = parseAbiItem([event]);
  viemClient.watchEvent({
    address: process.env.DATABASE_ADDRESS as Hex,
    event: parsedEvent,
    onLogs: (logs) => { const decodedLogs = decodeLogs(logs)
    console.log(decodedLogs)
    
    return decodedLogs
  }
  });
});


