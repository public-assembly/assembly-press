import { usePrepareContractWrite, useContractWrite, useWaitForTransaction } from "wagmi";
import { AP721DatabaseV1Abi } from "contracts";
import { optimismGoerli } from 'wagmi/chains';
import { Hex, Hash } from 'viem';

interface StoreProps {
    database: Hex;
    target: Hex;
    quantity: Number;
    data: Hash;
}

export function useStore({
    database,
    target,
    quantity,
    data
}: StoreProps) {

    const { config } = usePrepareContractWrite({
        address: database,
        abi: AP721DatabaseV1Abi,
        functionName: 'store',
        args: [target, quantity, data],
        chainId: optimismGoerli.id
    });

    const { data: storeData, write: store } = useContractWrite(config);

    const { isLoading: storeLoading, isSuccess: storeSuccess } = useWaitForTransaction({
        hash: storeData?.hash
    });

    return {
        store,
        storeLoading,
        storeSuccess
    };    
}