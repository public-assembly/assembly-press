import {
    usePrepareContractWrite,
    useContractWrite,
    useWaitForTransaction,
  } from 'wagmi';
  import { PrepareWriteContractResult } from 'wagmi/actions';
  import { optimismGoerli } from 'wagmi/chains';
  import { Hex, Hash } from 'viem';
  import { routerAbi } from '../contracts/abi';
  import { router } from '../contracts/constants';
  
  interface UpdatePressDataProps {
    press: Hex;
    data: Hash;
    prepareTxn: boolean;
  }
  
  interface UpdatePressDataReturn {
    updatePressDataConfig: PrepareWriteContractResult;
    updatePressData: (() => void) | undefined;
    updatePressDataLoading: boolean;
    updatePressDataSuccess: boolean;
  }
  
  export function useUpdatePressData({
     press,
     data,
     prepareTxn,
  }: UpdatePressDataProps): UpdatePressDataReturn {
    const { config: updatePressDataConfig } = usePrepareContractWrite({
      address: router,
      abi: routerAbi,
      functionName: 'updatePressData',
      args: [press, data],
      value: BigInt(500000000000000), 
      enabled: prepareTxn,
    });
  
    const { data: updatePressDataData, write: updatePressData } =
      useContractWrite(updatePressDataConfig);
  
    const { isLoading: updatePressDataLoading, isSuccess: updatePressDataSuccess } =
      useWaitForTransaction({
        hash: updatePressDataData?.hash,
      });
  
    return {
      updatePressDataConfig,
      updatePressData,
      updatePressDataLoading,
      updatePressDataSuccess,
    };
  }
  