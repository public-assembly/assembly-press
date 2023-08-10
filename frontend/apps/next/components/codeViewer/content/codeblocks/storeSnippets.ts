export const storeSnippets = {
    typescript:
    `export function useStore({ database, target, quantity, data }: StoreProps) {
        const { config } = usePrepareContractWrite({
          address: database,
          abi: AP721DatabaseV1Abi,
          functionName: 'store',
          args: [target, quantity, data],
          chainId: optimismGoerli.id,
        })
      
        const { data: storeData, write: store } = useContractWrite(config)
      
        const { isLoading: storeLoading, isSuccess: storeSuccess } =
          useWaitForTransaction({
            hash: storeData?.hash,
          })
      
        return {
          store,
          storeLoading,
          storeSuccess,
        }
      }`,
    solidity:
    `function store(address target, bytes memory data) external override(AP721DatabaseV1, IAP721Database) requireInitialized(target) {
        // Cache msg.sender
        address sender = msg.sender;
        // Decode token data
        bytes[] memory tokens = abi.decode(data, (bytes[]));        
        // Cache quantity
        uint256 quantity = tokens.length;        

        // Check if sender can store data in target
        if (!IAP721LogicAccess(ap721Settings[target].logic).getStoreAccess(target, sender, quantity)) revert No_Store_Access();

        // Store data for each token
        for (uint256 i = 0; i < quantity; ++i) {
            // Check data is valid
            _validateData(tokens[i]);
            // Cache storageCounter
            // NOTE: storageCounter trails associated tokenId by 1
            uint256 storageCounter = ap721Settings[target].storageCounter;
            // Use sstore2 to store bytes segments
            address pointer = tokenData[target][storageCounter] = SSTORE2.write(tokens[i]);
            emit DataStored(
                target,
                sender,
                storageCounter,
                pointer
            );
            // Increment target storageCounter after storing data
            ++ap721Settings[target].storageCounter;
        }
        // Mint tokens to sender
        IAP721(target).mint(sender, quantity);
    }`  
}