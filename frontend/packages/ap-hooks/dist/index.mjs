'use client'

// src/hooks/useStore.ts
import {
  usePrepareContractWrite,
  useContractWrite,
  useWaitForTransaction
} from "wagmi";

// src/contracts/AP721DatabaseV1Abi.ts
var AP721DatabaseV1Abi = [
  {
    inputs: [
      { internalType: "uint256", name: "_size", type: "uint256" },
      { internalType: "uint256", name: "_start", type: "uint256" },
      { internalType: "uint256", name: "_end", type: "uint256" }
    ],
    name: "InvalidCodeAtRange",
    type: "error"
  },
  { inputs: [], name: "Invalid_Input_Length", type: "error" },
  { inputs: [], name: "No_Overwrite_Access", type: "error" },
  { inputs: [], name: "No_Remove_Access", type: "error" },
  { inputs: [], name: "No_Settings_Access", type: "error" },
  { inputs: [], name: "No_Store_Access", type: "error" },
  { inputs: [], name: "Target_Not_Initialized", type: "error" },
  { inputs: [], name: "Token_Does_Not_Exist", type: "error" },
  { inputs: [], name: "WriteError", type: "error" },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "target",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      },
      {
        indexed: false,
        internalType: "address",
        name: "pointer",
        type: "address"
      }
    ],
    name: "DataOverwritten",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "target",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      }
    ],
    name: "DataRemoved",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "target",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256"
      },
      {
        indexed: false,
        internalType: "address",
        name: "pointer",
        type: "address"
      }
    ],
    name: "DataStored",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "target",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "logic",
        type: "address"
      }
    ],
    name: "LogicUpdated",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "target",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "renderer",
        type: "address"
      }
    ],
    name: "RendererUpdated",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "ap721",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "initialOwner",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "logic",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "renderer",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "factory",
        type: "address"
      }
    ],
    name: "SetupAP721",
    type: "event"
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "ap721Settings",
    outputs: [
      { internalType: "uint256", name: "storageCounter", type: "uint256" },
      { internalType: "address", name: "logic", type: "address" },
      { internalType: "uint8", name: "initialized", type: "uint8" },
      { internalType: "address", name: "renderer", type: "address" },
      {
        components: [
          { internalType: "address", name: "fundsRecipient", type: "address" },
          { internalType: "uint16", name: "royaltyBPS", type: "uint16" },
          { internalType: "bool", name: "transferable", type: "bool" }
        ],
        internalType: "struct IAP721Database.AP721Config",
        name: "ap721Config",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "sender", type: "address" }
    ],
    name: "canEditSettings",
    outputs: [{ internalType: "bool", name: "access", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "sender", type: "address" },
      { internalType: "uint256", name: "tokenId", type: "uint256" }
    ],
    name: "canOverwrite",
    outputs: [{ internalType: "bool", name: "access", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "sender", type: "address" },
      { internalType: "uint256", name: "tokenId", type: "uint256" }
    ],
    name: "canRemove",
    outputs: [{ internalType: "bool", name: "access", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "sender", type: "address" },
      { internalType: "uint256", name: "quantity", type: "uint256" }
    ],
    name: "canStore",
    outputs: [{ internalType: "bool", name: "access", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [],
    name: "contractURI",
    outputs: [{ internalType: "string", name: "uri", type: "string" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "target", type: "address" }],
    name: "getSettings",
    outputs: [
      {
        components: [
          { internalType: "uint256", name: "storageCounter", type: "uint256" },
          { internalType: "address", name: "logic", type: "address" },
          { internalType: "uint8", name: "initialized", type: "uint8" },
          { internalType: "address", name: "renderer", type: "address" },
          {
            components: [
              {
                internalType: "address",
                name: "fundsRecipient",
                type: "address"
              },
              { internalType: "uint16", name: "royaltyBPS", type: "uint16" },
              { internalType: "bool", name: "transferable", type: "bool" }
            ],
            internalType: "struct IAP721Database.AP721Config",
            name: "ap721Config",
            type: "tuple"
          }
        ],
        internalType: "struct IAP721Database.Settings",
        name: "",
        type: "tuple"
      }
    ],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "target", type: "address" }],
    name: "getTransferable",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "target", type: "address" }],
    name: "isInitialized",
    outputs: [{ internalType: "bool", name: "initialized", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256[]", name: "tokenIds", type: "uint256[]" },
      { internalType: "bytes[]", name: "data", type: "bytes[]" }
    ],
    name: "overwrite",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "target", type: "address" }],
    name: "readAllData",
    outputs: [{ internalType: "bytes[]", name: "allData", type: "bytes[]" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256", name: "tokenId", type: "uint256" }
    ],
    name: "readData",
    outputs: [{ internalType: "bytes", name: "data", type: "bytes" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256[]", name: "tokenIds", type: "uint256[]" }
    ],
    name: "remove",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "logic", type: "address" },
      { internalType: "bytes", name: "logicInit", type: "bytes" }
    ],
    name: "setLogic",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "address", name: "renderer", type: "address" },
      { internalType: "bytes", name: "rendererInit", type: "bytes" }
    ],
    name: "setRenderer",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "initialOwner", type: "address" },
      { internalType: "bytes", name: "databaseInit", type: "bytes" },
      { internalType: "address", name: "factory", type: "address" },
      { internalType: "bytes", name: "factoryInit", type: "bytes" }
    ],
    name: "setupAP721",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "target", type: "address" },
      { internalType: "uint256", name: "quantity", type: "uint256" },
      { internalType: "bytes", name: "data", type: "bytes" }
    ],
    name: "store",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "", type: "address" },
      { internalType: "uint256", name: "", type: "uint256" }
    ],
    name: "tokenData",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "uint256", name: "tokenId", type: "uint256" }],
    name: "tokenURI",
    outputs: [{ internalType: "string", name: "uri", type: "string" }],
    stateMutability: "view",
    type: "function"
  }
];

// src/hooks/useStore.ts
import { optimismGoerli } from "wagmi/chains";
function useStore({ database, target, quantity, data, prepareTxn }) {
  const { config } = usePrepareContractWrite({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "store",
    args: [target, quantity, data],
    chainId: optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: storeData, write: store } = useContractWrite(config);
  const { isLoading: storeLoading, isSuccess: storeSuccess } = useWaitForTransaction({
    hash: storeData == null ? void 0 : storeData.hash
  });
  return {
    // config,
    store,
    storeLoading,
    storeSuccess
  };
}

// src/hooks/useOverwrite.ts
import {
  usePrepareContractWrite as usePrepareContractWrite2,
  useContractWrite as useContractWrite2,
  useWaitForTransaction as useWaitForTransaction2
} from "wagmi";
import { optimismGoerli as optimismGoerli2 } from "wagmi/chains";
function useOverwrite({
  database,
  target,
  tokenIds,
  data,
  prepareTxn
}) {
  const { config } = usePrepareContractWrite2({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "overwrite",
    args: [target, tokenIds, data],
    chainId: optimismGoerli2.id,
    enabled: prepareTxn
  });
  const { data: overwriteData, write: overwrite } = useContractWrite2(config);
  const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } = useWaitForTransaction2({
    hash: overwriteData == null ? void 0 : overwriteData.hash
  });
  return {
    // config,
    overwrite,
    overwriteLoading,
    overwriteSuccess
  };
}

// src/hooks/useRemove.ts
import {
  usePrepareContractWrite as usePrepareContractWrite3,
  useContractWrite as useContractWrite3,
  useWaitForTransaction as useWaitForTransaction3
} from "wagmi";
import { optimismGoerli as optimismGoerli3 } from "wagmi/chains";
function useRemove({ database, target, tokenIds, prepareTxn }) {
  const { config } = usePrepareContractWrite3({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "remove",
    args: [target, tokenIds],
    chainId: optimismGoerli3.id,
    enabled: prepareTxn
  });
  const { data: removeData, write: remove } = useContractWrite3(config);
  const { isLoading: removeLoading, isSuccess: removeSuccess } = useWaitForTransaction3({
    hash: removeData == null ? void 0 : removeData.hash
  });
  return {
    // config,
    remove,
    removeLoading,
    removeSuccess
  };
}

// src/hooks/useSetLogic.ts
import {
  usePrepareContractWrite as usePrepareContractWrite4,
  useContractWrite as useContractWrite4,
  useWaitForTransaction as useWaitForTransaction4
} from "wagmi";
import { optimismGoerli as optimismGoerli4 } from "wagmi/chains";
function useSetLogic({
  database,
  target,
  logic,
  logicInit,
  prepareTxn
}) {
  const { config } = usePrepareContractWrite4({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setLogic",
    args: [target, logic, logicInit],
    chainId: optimismGoerli4.id,
    enabled: prepareTxn
  });
  const { data: setLogicData, write: setLogic } = useContractWrite4(config);
  const { isLoading: setLogicLoading, isSuccess: setLogicSuccess } = useWaitForTransaction4({
    hash: setLogicData == null ? void 0 : setLogicData.hash
  });
  return {
    // config,
    setLogic,
    setLogicLoading,
    setLogicSuccess
  };
}

// src/hooks/useSetRenderer.ts
import {
  usePrepareContractWrite as usePrepareContractWrite5,
  useContractWrite as useContractWrite5,
  useWaitForTransaction as useWaitForTransaction5
} from "wagmi";
import { optimismGoerli as optimismGoerli5 } from "wagmi/chains";
function useSetRenderer({
  database,
  target,
  renderer,
  rendererInit,
  prepareTxn
}) {
  const { config } = usePrepareContractWrite5({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setRenderer",
    args: [target, renderer, rendererInit],
    chainId: optimismGoerli5.id,
    enabled: prepareTxn
  });
  const { data: setRendererData, write: setRenderer } = useContractWrite5(config);
  const { isLoading: setRendererLoading, isSuccess: setRendererSuccess } = useWaitForTransaction5({
    hash: setRendererData == null ? void 0 : setRendererData.hash
  });
  return {
    // setRendererConfig: config,
    setRenderer,
    setRendererLoading,
    setRendererSuccess
  };
}

// src/hooks/useSetupAP721.ts
import {
  usePrepareContractWrite as usePrepareContractWrite6,
  useContractWrite as useContractWrite6,
  useWaitForTransaction as useWaitForTransaction6
} from "wagmi";
import { optimismGoerli as optimismGoerli6 } from "wagmi/chains";
function useSetupAP721({
  database,
  initialOwner,
  databaseInit,
  factory,
  factoryInit,
  prepareTxn
}) {
  const { config: setupAP721Config } = usePrepareContractWrite6({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setupAP721",
    args: [initialOwner, databaseInit, factory, factoryInit],
    chainId: optimismGoerli6.id,
    enabled: prepareTxn
  });
  const { data: setupAP721Data, write: setupAP721 } = useContractWrite6(setupAP721Config);
  const { isLoading: setupAP721Loading, isSuccess: setupAP721Success } = useWaitForTransaction6({
    hash: setupAP721Data == null ? void 0 : setupAP721Data.hash
  });
  return {
    setupAP721Config,
    setupAP721,
    setupAP721Loading,
    setupAP721Success
  };
}
export {
  useOverwrite,
  useRemove,
  useSetLogic,
  useSetRenderer,
  useSetupAP721,
  useStore
};
