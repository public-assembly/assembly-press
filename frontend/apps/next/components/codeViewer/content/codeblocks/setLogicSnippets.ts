export const setLogicSnippets = {
    typescript: 
    `export function useSetLogic({
        database,
        target,
        logic,
        logicInit,
    }: SetLogicProps) {
        const { config } = usePrepareContractWrite({
        address: database,
        abi: AP721DatabaseV1Abi,
        functionName: 'setLogic',
        args: [target, logic, logicInit],
        })
    
        const { data: setLogicData, write: setLogic } = useContractWrite(config)
    
        const { isLoading: setLogicLoading, isSuccess: setLogicSuccess } =
        useWaitForTransaction({
            hash: setLogicData?.hash,
        })
    
        return {
        setLogic,
        setLogicLoading,
        setLogicSuccess,
        }
    }`,
    solidity:
    `function setLogic(address target, address logic, bytes memory logicInit) 
        external 
        override(AP721DatabaseV1) 
        requireInitialized(target) 
    {
        // Request settings access from logic contract
        if (!IAP721LogicAccess(ap721Settings[target].logic).getSettingsAccess(target, msg.sender)) {
            revert No_Settings_Access();
        }
        // Update + initialize new logic contract
        _setLogic(target, logic, logicInit);
        emit LogicUpdated(target, logic);
    }`
}
