export const overwriteTokenDataSnippets = {
  typescript: `export function useOverwriteTokenData({
      press,
      data,
      prepareTxn,
    }: OverwriteTokenDataProps): OverwriteTokenDataReturn {
      const { config: overwriteTokenDataConfig } = usePrepareContractWrite({
        address: router,
        abi: routerAbi,
        functionName: 'overwriteTokenData',
        args: [press, data],
        value: BigInt(500000000000000),
        enabled: prepareTxn,
    });
  
    const { data: overwriteTokenDataData, write: overwriteTokenData } =
        useContractWrite(overwriteTokenDataConfig);
  
    const {
        isLoading: overwriteTokenDataLoading,
        isSuccess: overwriteTokenDataSuccess,
    } = useWaitForTransaction({
        hash: overwriteTokenDataData?.hash,
    });
  
    return {
        overwriteTokenDataConfig,
        overwriteTokenData,
        overwriteTokenDataLoading,
        overwriteTokenDataSuccess,
    };
  }`,
  solidity: `function overwriteTokenData(address press, bytes memory data) nonReentrant external payable {
    if (!pressRegistry[press]) revert Invalid_Press();
    (uint256[] memory tokenIds, address[] memory pointers) = IPress(press).overwriteTokenData{value: msg.value}(msg.sender, data);
    emit TokenDataOverwritten(msg.sender, press, tokenIds, pointers);
}    
`,
};
