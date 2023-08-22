export const setupSnippets = {
  typescript: `export function useSetup({
      factory,
      factoryInit,
      prepareTxn,
    }: SetupProps): SetupReturn {
      const { config: setupConfig } = usePrepareContractWrite({
        address: router,
        abi: routerAbi,
        functionName: "setup",
        args: [factory, factoryInit],
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
    }`,
  solidity: `    function setup(address factoryImpl, bytes memory factoryInit) nonReentrant external payable returns (address) {
      if (!factoryRegistry[factoryImpl]) revert Invalid_Factory();
      address press = IFactory(factoryImpl).createPress(msg.sender, factoryInit);
      pressRegistry[press] = true;
      emit PressRegistered(msg.sender, factoryImpl, press);
      return press;
  }`,
};
