import { Hex, Hash } from 'viem';

interface StoreProps {
    database: Hex;
    target: Hex;
    quantity: bigint;
    data: Hash;
}
declare function useStore({ database, target, quantity, data }: StoreProps): {
    store: (() => void) | undefined;
    storeLoading: boolean;
    storeSuccess: boolean;
};

interface OverwriteProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
    data: Hash[];
}
declare function useOverwrite({ database, target, tokenIds, data, }: OverwriteProps): {
    overwrite: (() => void) | undefined;
    overwriteLoading: boolean;
    overwriteSuccess: boolean;
};

interface RemoveProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
}
declare function useRemove({ database, target, tokenIds }: RemoveProps): {
    remove: (() => void) | undefined;
    removeLoading: boolean;
    removeSuccess: boolean;
};

interface SetLogicProps {
    database: Hex;
    target: Hex;
    logic: Hex;
    logicInit: Hash;
}
declare function useSetLogic({ database, target, logic, logicInit, }: SetLogicProps): {
    setLogic: (() => void) | undefined;
    setLogicLoading: boolean;
    setLogicSuccess: boolean;
};

interface SetRendererProps {
    database: Hex;
    target: Hex;
    renderer: Hex;
    rendererInit: Hash;
}
declare function useSetRenderer({ database, target, renderer, rendererInit, }: SetRendererProps): {
    setRenderer: (() => void) | undefined;
    setRendererLoading: boolean;
    setRendererSuccess: boolean;
};

interface SetupAP721Props {
    database: Hex;
    initialOwner: Hex;
    databaseInit: Hash;
    factory: Hex;
    factoryInit: Hash;
}
declare function useSetupAP721({ database, initialOwner, databaseInit, factory, factoryInit, }: SetupAP721Props): {
    setupAP721: (() => void) | undefined;
    setupAP721Loading: boolean;
    setupAP721Success: boolean;
};

export { useOverwrite, useRemove, useSetLogic, useSetRenderer, useSetupAP721, useStore };
