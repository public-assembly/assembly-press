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

interface OverwriteTokenDataProps {
  press: Hex;
  data: Hash;
  prepareTxn: boolean;
}

interface OverwriteTokenDataReturn {
  overwriteTokenDataConfig: PrepareWriteContractResult;
  overwriteTokenData: (() => void) | undefined;
  overwriteTokenDataLoading: boolean;
  overwriteTokenDataSuccess: boolean;
}

export function useOverwriteTokenData({
  press,
  data,
  prepareTxn,
}: OverwriteTokenDataProps): OverwriteTokenDataReturn {
  const { config: overwriteTokenDataConfig } = usePrepareContractWrite({
    address: router,
    abi: routerAbi,
    functionName: "overwriteTokenData",
    args: [press, data],
    chainId: optimismGoerli.id,
    value: BigInt(0), // maybe this 500000000000000
    enabled: prepareTxn
  });

  const { data: overwriteTokenDataData, write: overwriteTokenData } = useContractWrite(overwriteTokenDataConfig);

  const { isLoading: overwriteTokenDataLoading, isSuccess: overwriteTokenDataSuccess } =
    useWaitForTransaction({
      hash: overwriteTokenDataData?.hash,
    });

  return {
    overwriteTokenDataConfig,
    overwriteTokenData,
    overwriteTokenDataLoading,
    overwriteTokenDataSuccess,
  };
}
