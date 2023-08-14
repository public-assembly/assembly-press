import { PrepareWriteContractResult } from 'wagmi/actions';
import { Hex, Hash } from 'viem';

interface StoreProps {
    database: Hex;
    target: Hex;
    quantity: bigint;
    data: Hash;
    prepareTxn: boolean;
}
interface StoreReturn {
    storeConfig: PrepareWriteContractResult;
    store: (() => void) | undefined;
    storeLoading: boolean;
    storeSuccess: boolean;
}
declare function useStore({ database, target, quantity, data, prepareTxn }: StoreProps): StoreReturn;

interface OverwriteProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
    data: Hash[];
    prepareTxn: boolean;
}
interface OverwriteReturn {
    overwriteConfig: PrepareWriteContractResult;
    overwrite: (() => void) | undefined;
    overwriteLoading: boolean;
    overwriteSuccess: boolean;
}
declare function useOverwrite({ database, target, tokenIds, data, prepareTxn }: OverwriteProps): OverwriteReturn;

interface RemoveProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
    prepareTxn: boolean;
}
interface RemoveReturn {
    removeConfig: PrepareWriteContractResult;
    remove: (() => void) | undefined;
    removeLoading: boolean;
    removeSuccess: boolean;
}
declare function useRemove({ database, target, tokenIds, prepareTxn }: RemoveProps): RemoveReturn;

interface SetLogicProps {
    database: Hex;
    target: Hex;
    logic: Hex;
    logicInit: Hash;
    prepareTxn: boolean;
}
interface SetLogicReturn {
    setLogicConfig: PrepareWriteContractResult;
    setLogic: (() => void) | undefined;
    setLogicLoading: boolean;
    setLogicSuccess: boolean;
}
declare function useSetLogic({ database, target, logic, logicInit, prepareTxn }: SetLogicProps): SetLogicReturn;

interface SetRendererProps {
    database: Hex;
    target: Hex;
    renderer: Hex;
    rendererInit: Hash;
    prepareTxn: boolean;
}
interface SetRendererReturn {
    setRendererConfig: PrepareWriteContractResult;
    setRenderer: (() => void) | undefined;
    setRendererLoading: boolean;
    setRendererSuccess: boolean;
}
declare function useSetRenderer({ database, target, renderer, rendererInit, prepareTxn, }: SetRendererProps): SetRendererReturn;

interface SetupAP721Props {
    database: Hex;
    initialOwner: Hex;
    databaseInit: Hash;
    factory: Hex;
    factoryInit: Hash;
    prepareTxn: boolean;
}
interface SetupAP721Return {
    setupAP721Config: PrepareWriteContractResult;
    setupAP721: (() => void) | undefined;
    setupAP721Loading: boolean;
    setupAP721Success: boolean;
}
declare function useSetupAP721({ database, initialOwner, databaseInit, factory, factoryInit, prepareTxn, }: SetupAP721Props): SetupAP721Return;

export { useOverwrite, useRemove, useSetLogic, useSetRenderer, useSetupAP721, useStore };
