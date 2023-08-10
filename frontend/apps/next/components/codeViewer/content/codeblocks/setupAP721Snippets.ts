export const setupAP721Snippets = {
    typescript:
    `export function useSetupAP721({
        database,
        initialOwner,
        databaseInit,
        factory,
        factoryInit,
      }: SetupAP721Props) {
        const { config } = usePrepareContractWrite({
          address: database,
          abi: AP721DatabaseV1Abi,
          functionName: 'setupAP721',
          args: [initialOwner, databaseInit, factory, factoryInit],
          chainId: optimismGoerli.id,
        })
      
        const { data: setupAP721Data, write: setupAP721 } = useContractWrite(config)
      
        const { isLoading: setupAP721Loading, isSuccess: setupAP721Success } =
          useWaitForTransaction({
            hash: setupAP721Data?.hash,
          })
      
        return {
          setupAP721,
          setupAP721Loading,
          setupAP721Success,
        }
      }`,
    solidity:
    `function setupAP721(address initialOwner, bytes memory databaseInit, address factory, bytes memory factoryInit)
        external
        virtual
        nonReentrant
        returns (address)
    {
        // Call factory to create + initialize a new AP721Proxy
        address newAP721 = IAP721Factory(factory).create(initialOwner, factoryInit);
        // Decode database init
        (address logic, address renderer, bool transferable, bytes memory logicInit, bytes memory rendererInit)
            = abi.decode(databaseInit, (address, address, bool, bytes, bytes));
        // Initializes AP721Proxy in database + sets transferable in ap721Config
        _setSettings(newAP721, transferable);
        // Set + initialize logic
        _setLogic(newAP721, logic, logicInit);
        // Set + initialize renderer
        _setRenderer(newAP721, renderer, rendererInit);
        // Emit setup event
        emit SetupAP721({
            ap721: newAP721,
            sender: msg.sender,
            initialOwner: initialOwner,
            logic: logic,
            renderer: renderer,
            factory: factory
        });
        // Return address of newly created AP721Proxy
        return newAP721;
    }`
}