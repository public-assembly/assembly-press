import { usePrepareContractWrite, useContractWrite, useWaitForTransaction } from "wagmi";
import { AP721DatabaseV1Abi } from "../contracts";
import { optimismGoerli } from 'wagmi/chains';
import { Hex, Hash } from 'viem';

interface OverwriteProps {
    database: Hex;
    target: Hex;
    tokenIds: Number[];
    data: Hash[];
}

export function useOverwrite({
    database,
    target,
    tokenIds,
    data
}: OverwriteProps) {

    const { config } = usePrepareContractWrite({
        address: database,
        abi: AP721DatabaseV1Abi,
        functionName: 'overwrite',
        args: [target, tokenIds, data],
        chainId: optimismGoerli.id
    });

    const { data: overwriteData, write: overwrite } = useContractWrite(config);

    const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } = useWaitForTransaction({
        hash: overwriteData?.hash
    });

    return {
        overwrite,
        overwriteLoading,
        overwriteSuccess
    };    
}