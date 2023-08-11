"use client";

import { useFunctionSelect } from "context/FunctionSelectProvider";
import { Flex, CaptionLarge } from "../base";
import {
  useSetupAP721,
  useSetLogic,
  useSetRenderer,
  useStore,
  useOverwrite,
} from "@public-assembly/ap-hooks";
import { useAccount } from "wagmi";

export const TxnSubmitter = () => {
  // Get current selector from global context
  const { selector } = useFunctionSelect();
  // Get address of current authd user
  const { address } = useAccount();
  // Get prepareTxn value for hooks
  const user = address ? address : false;

  const { setupAP721 } = useSetupAP721();

  const handleTxn = () => {};

  return (
    <div>
      <Flex className="flex-col w-full content-between px-6 py-3"></Flex>
    </div>
  );
};
