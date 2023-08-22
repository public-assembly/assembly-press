export const storeSnippets = {
  typescript: `export function useStoreTokenData({
      press,
      data,
      prepareTxn,
    }: StoreTokenDataProps): StoreTokenDataReturn {
      const { config: storeTokenDataConfig } = usePrepareContractWrite({
        address: router,
        abi: routerAbi,
        functionName: 'storeTokenData',
        args: [press, data],
        value: BigInt(500000000000000),
        enabled: prepareTxn,
      });
    
      const { data: storeTokenDataData, write: storeTokenData } =
        useContractWrite(storeTokenDataConfig);
    
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
    }`,
  solidity: ` function storeTokenData(address press, bytes memory data) nonReentrant external payable {
      if (!pressRegistry[press]) revert Invalid_Press();
      (uint256[] memory tokenIds, address[] memory pointers) = IPress(press).storeTokenData{value: msg.value}(msg.sender, data);
      emit TokenDataStored(msg.sender, press, tokenIds, pointers);
  }`,
};
