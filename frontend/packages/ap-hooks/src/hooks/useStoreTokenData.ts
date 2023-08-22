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
  
  interface StoreTokenDataProps {
    press: Hex;
    data: Hash;
    prepareTxn: boolean;
  }
  
  interface StoreTokenDataReturn {
    storeTokenDataConfig: PrepareWriteContractResult;
    storeTokenData: (() => void) | undefined;
    storeTokenDataLoading: boolean;
    storeTokenDataSuccess: boolean;
  }
  
  export function useStoreTokenData({
    press,
    data,
    prepareTxn,
  }: StoreTokenDataProps): StoreTokenDataReturn {
    const { config: storeTokenDataConfig } = usePrepareContractWrite({
      address: router,
      abi: routerAbi,
      functionName: "storeTokenData",
      args: [press, data],
      chainId: optimismGoerli.id,
      value: BigInt(500000000000000),
      enabled: prepareTxn
    });
  
    const { data: storeTokenDataData, write: storeTokenData } = useContractWrite(storeTokenDataConfig);
  
    const { isLoading: storeTokenDataLoading, isSuccess: storeTokenDataSuccess } =
      useWaitForTransaction({
        hash: storeTokenDataData?.hash,
      });
  
    return {
      storeTokenDataConfig,
      storeTokenData,
      storeTokenDataLoading,
      storeTokenDataSuccess,
    };
  }
  