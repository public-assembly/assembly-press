export const overwriteSnippets = {
  typescript: `export function useOverwrite({ database, target, tokenIds, data }) {
        const { config } = usePrepareContractWrite({
          address: database,
          abi: AP721DatabaseV1Abi,
          functionName: 'overwrite',
          args: [target, tokenIds, data],
        })
      
        const { data: overwriteData, write: overwrite } = useContractWrite(config)
      
        const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } =
          useWaitForTransaction({
            hash: overwriteData?.hash,
          })
      
        return {
          overwrite,
          overwriteLoading,
          overwriteSuccess,
        }
    }`,
  solidity: `function overwrite(address target, uint256[] memory tokenIds, bytes[] memory data)
        external
        override(AP721DatabaseV1, IAP721Database)
        requireInitialized(target)
    {
        // Prevents users from submitting invalid inputs
        if (tokenIds.length != data.length) {
            revert Invalid_Input_Length();
        }
        // Cache msg.sender
        address sender = msg.sender;

        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Check if tokenId exists
            if (!AP721(payable(target)).exists(tokenIds[i])) revert Token_Does_Not_Exist();
            // Check if sender can overwrite data in target for given tokenId
            if (!IAP721LogicAccess(ap721Settings[target].logic).getOverwriteAccess(target, sender, tokenIds[i])) revert No_Overwrite_Access();
            // Check data is valid
            _validateData(data[i]);
            // Cache storageCounter for tokenId
            uint256 storageCounter = tokenIds[i] - 1;
            // Use sstore2 to store bytes segments
            address newPointer = tokenData[target][storageCounter] = SSTORE2.write(data[i]);
            emit DataOverwritten(target, sender, storageCounter, newPointer);
        }
    }`,
};
