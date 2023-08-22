import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction,
} from "wagmi";
import { PrepareWriteContractResult } from "wagmi/actions";
import { optimismGoerli } from "wagmi/chains";
import { Hex, Hash } from "viem";
import { routerAbi } from "../contracts/abi";
import { router } from "../contracts/constants";

interface SetupProps {
  factory: Hex;
  factoryInit: Hash;
  prepareTxn: boolean;
}

interface SetupReturn {
  setupConfig: PrepareWriteContractResult;
  setup: (() => void) | undefined;
  setupLoading: boolean;
  setupSuccess: boolean;
}

export function useSetup({
  factory,
  factoryInit,
  prepareTxn,
}: SetupProps): SetupReturn {
  const { config: setupConfig } = usePrepareContractWrite({
    address: router,
    abi: routerAbi,
    functionName: "setup",
    args: [factory, factoryInit],
    chainId: optimismGoerli.id,
    value: BigInt(0),
    enabled: prepareTxn,
  });

  const { data: setupData, write: setup } = useContractWrite(setupConfig);

  const { isLoading: setupLoading, isSuccess: setupSuccess } =
    useWaitForTransaction({
      hash: setupData?.hash,
    });

  return {
    setupConfig,
    setup,
    setupLoading,
    setupSuccess,
  };
}
