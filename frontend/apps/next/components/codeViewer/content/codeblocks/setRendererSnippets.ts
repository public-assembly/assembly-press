export const setRendererSnippets = {
    typescript: 
    `export function useSetRenderer({
        database,
        target,
        renderer,
        rendererInit,
      }: SetRendererProps) {
        const { config } = usePrepareContractWrite({
          address: database,
          abi: AP721DatabaseV1Abi,
          functionName: 'setRenderer',
          args: [target, renderer, rendererInit],
        })
      
        const { data: setRendererData, write: setRenderer } = useContractWrite(config)
      
        const { isLoading: setRendererLoading, isSuccess: setRendererSuccess } =
          useWaitForTransaction({
            hash: setRendererData?.hash,
          })
      
        return {
          setRenderer,
          setRendererLoading,
          setRendererSuccess,
        }
      }`,
    solidity:
    `function setRenderer(address target, address renderer, bytes memory rendererInit) 
        external 
        override(AP721DatabaseV1) 
        requireInitialized(target) 
    {
        // Request settings access from renderer contract
        if (!IAP721LogicAccess(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) revert No_Settings_Access();
        // Update + initialize new renderer contract
        _setRenderer(target, renderer, rendererInit);
        emit RendererUpdated(target, renderer);
    }`
}
