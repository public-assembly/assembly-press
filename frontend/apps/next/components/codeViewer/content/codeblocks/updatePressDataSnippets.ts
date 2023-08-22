export const updatePressDataSnippets = {
  // rome-ignore lint:
  typescript: `export function useUpdatePressData({
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
  
      const { isLoading: updatePressDataLoading,
      isSuccess: updatePressDataSuccess } =
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
  `,
  solidity: `function updatePressData(address press, bytes memory data) nonReentrant external payable {
        if (!pressRegistry[press]) revert Invalid_Press();
        (address pointer) = IPress(press).updatePressData{value: msg.value}(msg.sender, data);
        emit PressDataUpdated(msg.sender, press, pointer);
    }         `,
};
