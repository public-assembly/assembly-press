import { viemClient } from "../viem/client";
import { pressAbi } from "../abi";
import { DecodedRouterEvent } from "./decodeLogs";

export async function processLogs(decodedLogs: DecodedRouterEvent[]) {
  // @ts-ignore
  const processedLogs = await Promise.all(
    decodedLogs.map(async (log) => {
      if (log.eventName === "PressRegistered") {
        const additionalData = await viemClient.readContract({
          // @ts-ignore
          address: log.args.newPress,
          abi: pressAbi,
          functionName: "settings",
        });
        return {
          ...log,
          additionalData,
        };
      }
      return log
    })
  );
  return processedLogs;
}
