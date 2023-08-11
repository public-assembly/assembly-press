"use client";

import { useFunctionSelect } from "context/FunctionSelectProvider";
import { Flex, CaptionLarge } from "../base";
import {
  useSetupAP721,
  useSetLogic,
  useSetRenderer,
  useStore,
  useOverwrite,
} from "@public-assembly/ap-hooks";
import { useAccount } from "wagmi";
import { Hash, Hex, encodeAbiParameters, parseAbiParameters } from "viem";
import { Button } from "../Button";
import { shortenAddress } from "@/utils/shortenAddress";

const databaseImpl: Hex = "0xFE16d7a18A1c00e8f07Ca11A1d29e69A69d67d7b";
const factoryImpl: Hex = "0x506615B90099d2d7031B34f455A5803F5Cae68Cb";
const logicImpl: Hex = "0x9c9FA39424F755F2a82eE01cb6a91212F300f55d";
const rendererImpl: Hex = "0x92964176f59080c5785fAAB8318B32638ec37970";
const emptyInit: Hex = "0x";
const existingAP721: Hex = "0x2F2882485D87D21230e9369ED73aDdbE4671c0BF";

export const TxnSubmitter = () => {
  // Get current selector from global context
  const { selector } = useFunctionSelect();
  // Get address of current authd user
  const { address } = useAccount();
  // Get prepareTxn value for hooks
  const user = address ? true : false;

  /* SetupAP721 Hook */
  const databaseInitInput: Hash = encodeAbiParameters(
    parseAbiParameters('address, address, bool, bytes, bytes'),
    [logicImpl, rendererImpl, false, emptyInit, emptyInit]
  );

  const factoryInitInput: Hash = encodeAbiParameters(
    parseAbiParameters('string, string'),
    ['AssemblyPress', 'AP'] // name + symbol
  );  

  const { setupAP721, setupAP721Loading, setupAP721Success } = useSetupAP721({
    database: databaseImpl,
    databaseInit: databaseInitInput,
    initialOwner: address,
    factory: factoryImpl,
    factoryInit: factoryInitInput,
    prepareTxn: user
  });

//   console.log("setupAP721config", setupAP721Config)

  /* SetLogic Hook */
  const { setLogic, setLogicLoading, setLogicSuccess } = useSetLogic({
    database: databaseImpl,
    target: existingAP721,
    logic: logicImpl,
    logicInit: emptyInit,
    prepareTxn: user
  });

  /* SetRenderer Hook */
  const { setRenderer, setRendererLoading, setRendererSuccess } =
    useSetRenderer({
      database: databaseImpl,
      target: existingAP721,
      renderer: rendererImpl,
      rendererInit: emptyInit,
      prepareTxn: user
    });

  /* Store Hook */
  const encodedString: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['Lifeworld']
  );

  const encodedBytesArray: Hash = encodeAbiParameters(
    parseAbiParameters('bytes[]'),
    [[encodedString]]
  );

  const { store, storeLoading, storeSuccess } = useStore({
    database: databaseImpl,
    target: existingAP721,
    quantity: BigInt(1),
    data: encodedBytesArray,
    prepareTxn: user
  });

  /* Overwrite Hook */
  const encodedString2: Hash = encodeAbiParameters(
    parseAbiParameters('string'),
    ['River']
  );

  const arrayOfBytes: Hash[] = [encodedString2];

  const { overwrite, overwriteLoading, overwriteSuccess } = useOverwrite({
    database: databaseImpl,
    target: existingAP721,
    tokenIds: [BigInt(1)],
    data: arrayOfBytes,
    prepareTxn: user
  });  

    const handleTxn = () => {
        switch(selector) {
            case 0:
                console.log("running setupAP721")
                setupAP721?.()
                break
            case 1:
                console.log("running setLogic")
                setLogic?.()
                break
            case 2:
                console.log("running setRenderer")
                setRenderer?.()                
                break
            case 3:
                console.log("running store")        
                store?.()                        
                break
            case 4:
                console.log("running overwrite")            
                overwrite?.()                    
                break
        }
    };

    // Map selector values to corresponding snippets
    const functionNameMap = {
        0: "setupAP721",
        1: "setLogic",
        2: "setRenderer",
        3: "store",
        4: "overwrite"
    };

    // const functionLoadingMap = {
    //     0: setupAP721Loading,
    //     1: setLogicLoading,
    //     2: setRendererLoading,
    //     3: storeLoading,
    //     4: overwriteLoading
    // };    

    // const activeFunctionLoading = () => {
    //     console.log("selector: ", selector)
    //     console.log("loading?: ", functionLoadingMap?.[selector])
    //     return functionLoadingMap?.[selector]
    // }

    // const functionConfigMap = {
    //     0: setupAP721Config,
    //     1: setLogicConfig,
    //     2: setRenderer,
    //     3: storeConfig,
    //     4: overwriteConfig
    // };    

    // const parsedActiveArgs = () => {
    //     return functionConfigMap?.[selector].request?.args
    // }

  return (
    <Flex className="flex-col justify-between h-full w-full  px-6 py-3">
        <div className="flex flex-wrap gap-y-4 mb-10">
            <div className="flex w-full">{`From: ${shortenAddress(address)}`}</div>
            <div className="flex w-full">{`To: ${shortenAddress(databaseImpl)}`}</div>
        </div>
        <div className="flex flex-wrap gap-y-2">
            <div className="flex w-full">{"Args:"}</div>
            <div className="p-2 flex w-full h-[200px] bg-[#232528] text-[#A7A8A9] overflow-y-auto">{"[placholder]: should be filled with prepConfig from active function"}</div>
        </div>    
        <Button text={"Submit Txn"} callback={handleTxn} callbackLoading={false} />
    </Flex>
  )
};

