'use client'
"use strict";
var __defProp = Object.defineProperty;
var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};
var __copyProps = (to, from, except, desc) => {
  if (from && typeof from === "object" || typeof from === "function") {
    for (let key of __getOwnPropNames(from))
      if (!__hasOwnProp.call(to, key) && key !== except)
        __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
  }
  return to;
};
var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

// src/index.ts
var src_exports = {};
__export(src_exports, {
  useOverwrite: () => useOverwrite,
  useRemove: () => useRemove,
  useSetLogic: () => useSetLogic,
  useSetRenderer: () => useSetRenderer,
  useSetupAP721: () => useSetupAP721,
  useStore: () => useStore
});
module.exports = __toCommonJS(src_exports);

// src/hooks/useStore.ts
var import_wagmi = require("wagmi");

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
var import_chains = require("wagmi/chains");
function useStore({ database, target, quantity, data, prepareTxn }) {
  const { config } = (0, import_wagmi.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "store",
    args: [target, quantity, data],
    chainId: import_chains.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: storeData, write: store } = (0, import_wagmi.useContractWrite)(config);
  const { isLoading: storeLoading, isSuccess: storeSuccess } = (0, import_wagmi.useWaitForTransaction)({
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
var import_wagmi2 = require("wagmi");
var import_chains2 = require("wagmi/chains");
function useOverwrite({
  database,
  target,
  tokenIds,
  data,
  prepareTxn
}) {
  const { config } = (0, import_wagmi2.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "overwrite",
    args: [target, tokenIds, data],
    chainId: import_chains2.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: overwriteData, write: overwrite } = (0, import_wagmi2.useContractWrite)(config);
  const { isLoading: overwriteLoading, isSuccess: overwriteSuccess } = (0, import_wagmi2.useWaitForTransaction)({
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
var import_wagmi3 = require("wagmi");
var import_chains3 = require("wagmi/chains");
function useRemove({ database, target, tokenIds, prepareTxn }) {
  const { config } = (0, import_wagmi3.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "remove",
    args: [target, tokenIds],
    chainId: import_chains3.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: removeData, write: remove } = (0, import_wagmi3.useContractWrite)(config);
  const { isLoading: removeLoading, isSuccess: removeSuccess } = (0, import_wagmi3.useWaitForTransaction)({
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
var import_wagmi4 = require("wagmi");
var import_chains4 = require("wagmi/chains");
function useSetLogic({
  database,
  target,
  logic,
  logicInit,
  prepareTxn
}) {
  const { config } = (0, import_wagmi4.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setLogic",
    args: [target, logic, logicInit],
    chainId: import_chains4.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: setLogicData, write: setLogic } = (0, import_wagmi4.useContractWrite)(config);
  const { isLoading: setLogicLoading, isSuccess: setLogicSuccess } = (0, import_wagmi4.useWaitForTransaction)({
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
var import_wagmi5 = require("wagmi");
var import_chains5 = require("wagmi/chains");
function useSetRenderer({
  database,
  target,
  renderer,
  rendererInit,
  prepareTxn
}) {
  const { config: setRendererConfig } = (0, import_wagmi5.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setRenderer",
    args: [target, renderer, rendererInit],
    chainId: import_chains5.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: setRendererData, write: setRenderer } = (0, import_wagmi5.useContractWrite)(setRendererConfig);
  const { isLoading: setRendererLoading, isSuccess: setRendererSuccess } = (0, import_wagmi5.useWaitForTransaction)({
    hash: setRendererData == null ? void 0 : setRendererData.hash
  });
  return {
    setRendererConfig,
    setRenderer,
    setRendererLoading,
    setRendererSuccess
  };
}

// src/hooks/useSetupAP721.ts
var import_wagmi6 = require("wagmi");
var import_chains6 = require("wagmi/chains");
function useSetupAP721({
  database,
  initialOwner,
  databaseInit,
  factory,
  factoryInit,
  prepareTxn
}) {
  const { config: setupAP721Config } = (0, import_wagmi6.usePrepareContractWrite)({
    address: database,
    abi: AP721DatabaseV1Abi,
    functionName: "setupAP721",
    args: [initialOwner, databaseInit, factory, factoryInit],
    chainId: import_chains6.optimismGoerli.id,
    enabled: prepareTxn
  });
  const { data: setupAP721Data, write: setupAP721 } = (0, import_wagmi6.useContractWrite)(setupAP721Config);
  const { isLoading: setupAP721Loading, isSuccess: setupAP721Success } = (0, import_wagmi6.useWaitForTransaction)({
    hash: setupAP721Data == null ? void 0 : setupAP721Data.hash
  });
  return {
    setupAP721Config,
    setupAP721,
    setupAP721Loading,
    setupAP721Success
  };
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  useOverwrite,
  useRemove,
  useSetLogic,
  useSetRenderer,
  useSetupAP721,
  useStore
});
