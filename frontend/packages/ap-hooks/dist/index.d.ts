import { PrepareWriteContractResult } from 'wagmi/actions';
import { Hex, Hash } from 'viem';

interface SetupProps {
    factory: Hex;
    factoryInit: Hash;
    prepareTxn: boolean;
}
interface SetupReturn {
    setupConfig: PrepareWriteContractResult;
    setup: (() => void) | undefined;
    setupLoading: boolean;
    setupSuccess: boolean;
}
declare function useSetup({ factory, factoryInit, prepareTxn, }: SetupProps): SetupReturn;

interface StoreTokenDataProps {
    press: Hex;
    data: Hash;
    prepareTxn: boolean;
}
interface StoreTokenDataReturn {
    storeTokenDataConfig: PrepareWriteContractResult;
    storeTokenData: (() => void) | undefined;
    storeTokenDataLoading: boolean;
    storeTokenDataSuccess: boolean;
}
declare function useStoreTokenData({ press, data, prepareTxn, }: StoreTokenDataProps): StoreTokenDataReturn;

interface OverwriteTokenDataProps {
    press: Hex;
    data: Hash;
    prepareTxn: boolean;
}
interface OverwriteTokenDataReturn {
    overwriteTokenDataConfig: PrepareWriteContractResult;
    overwriteTokenData: (() => void) | undefined;
    overwriteTokenDataLoading: boolean;
    overwriteTokenDataSuccess: boolean;
}
declare function useOverwriteTokenData({ press, data, prepareTxn, }: OverwriteTokenDataProps): OverwriteTokenDataReturn;

export { useOverwriteTokenData, useSetup, useStoreTokenData };
