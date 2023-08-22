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
  useOverwriteTokenData: () => useOverwriteTokenData,
  useSetup: () => useSetup,
  useStoreTokenData: () => useStoreTokenData
});
module.exports = __toCommonJS(src_exports);

// src/hooks/useSetup.ts
var import_wagmi = require("wagmi");

// src/contracts/abi/routerAbi.ts
var routerAbi = [
  { inputs: [], name: "Input_Length_Mistmatch", type: "error" },
  { inputs: [], name: "Invalid_Factory", type: "error" },
  { inputs: [], name: "Invalid_Press", type: "error" },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address[]",
        name: "factories",
        type: "address[]"
      },
      {
        indexed: false,
        internalType: "bool[]",
        name: "statuses",
        type: "bool[]"
      }
    ],
    name: "FactoryRegistered",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address"
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address"
      }
    ],
    name: "OwnershipTransferred",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "press",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "pointer",
        type: "address"
      }
    ],
    name: "PressDataUpdated",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "factory",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "newPress",
        type: "address"
      }
    ],
    name: "PressRegistered",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "press",
        type: "address"
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "tokenIds",
        type: "uint256[]"
      },
      {
        indexed: false,
        internalType: "address[]",
        name: "pointers",
        type: "address[]"
      }
    ],
    name: "TokenDataOverwritten",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "press",
        type: "address"
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "tokenIds",
        type: "uint256[]"
      }
    ],
    name: "TokenDataRemoved",
    type: "event"
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "sender",
        type: "address"
      },
      {
        indexed: false,
        internalType: "address",
        name: "press",
        type: "address"
      },
      {
        indexed: false,
        internalType: "uint256[]",
        name: "tokenIds",
        type: "uint256[]"
      },
      {
        indexed: false,
        internalType: "address[]",
        name: "pointers",
        type: "address[]"
      }
    ],
    name: "TokenDataStored",
    type: "event"
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "factoryRegistry",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "press", type: "address" },
      { internalType: "bytes", name: "data", type: "bytes" }
    ],
    name: "overwriteTokenData",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "presses", type: "address[]" },
      { internalType: "bytes[]", name: "datas", type: "bytes[]" }
    ],
    name: "overwriteTokenDataMulti",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [],
    name: "owner",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "", type: "address" }],
    name: "pressRegistry",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "view",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "factories", type: "address[]" },
      { internalType: "bool[]", name: "statuses", type: "bool[]" }
    ],
    name: "registerFactories",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "press", type: "address" },
      { internalType: "bytes", name: "data", type: "bytes" }
    ],
    name: "removeTokenData",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "presses", type: "address[]" },
      { internalType: "bytes[]", name: "datas", type: "bytes[]" }
    ],
    name: "removeTokenDataMulti",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "factoryImpl", type: "address" },
      { internalType: "bytes", name: "factoryInit", type: "bytes" }
    ],
    name: "setup",
    outputs: [{ internalType: "address", name: "", type: "address" }],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "factoryImpls", type: "address[]" },
      { internalType: "bytes[]", name: "factoryInits", type: "bytes[]" }
    ],
    name: "setupBatch",
    outputs: [{ internalType: "address[]", name: "", type: "address[]" }],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "press", type: "address" },
      { internalType: "bytes", name: "data", type: "bytes" }
    ],
    name: "storeTokenData",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "presses", type: "address[]" },
      { internalType: "bytes[]", name: "datas", type: "bytes[]" }
    ],
    name: "storeTokenDataMulti",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [{ internalType: "address", name: "newOwner", type: "address" }],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address", name: "press", type: "address" },
      { internalType: "bytes", name: "data", type: "bytes" }
    ],
    name: "updatePressData",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  },
  {
    inputs: [
      { internalType: "address[]", name: "presses", type: "address[]" },
      { internalType: "bytes[]", name: "datas", type: "bytes[]" }
    ],
    name: "updatePressDataMulti",
    outputs: [],
    stateMutability: "payable",
    type: "function"
  }
];

// src/contracts/constants.ts
var router = "0x7539973c756c45bf0ecc4167d6ce9750c60f903d";

// src/hooks/useSetup.ts
function useSetup({
  factory,
  factoryInit,
  prepareTxn
}) {
  const { config: setupConfig } = (0, import_wagmi.usePrepareContractWrite)({
    address: router,
    abi: routerAbi,
    functionName: "setup",
    args: [factory, factoryInit],
    // chainId: optimismGoerli.id,
    value: BigInt(0),
    enabled: prepareTxn
  });
  const { data: setupData, write: setup } = (0, import_wagmi.useContractWrite)(setupConfig);
  const { isLoading: setupLoading, isSuccess: setupSuccess } = (0, import_wagmi.useWaitForTransaction)({
    hash: setupData == null ? void 0 : setupData.hash
  });
  return {
    setupConfig,
    setup,
    setupLoading,
    setupSuccess
  };
}

// src/hooks/useStoreTokenData.ts
var import_wagmi2 = require("wagmi");
function useStoreTokenData({
  press,
  data,
  prepareTxn
}) {
  const { config: storeTokenDataConfig } = (0, import_wagmi2.usePrepareContractWrite)({
    address: router,
    abi: routerAbi,
    functionName: "storeTokenData",
    args: [press, data],
    // chainId: optimismGoerli.id,
    value: BigInt(5e14),
    enabled: prepareTxn
  });
  const { data: storeTokenDataData, write: storeTokenData } = (0, import_wagmi2.useContractWrite)(storeTokenDataConfig);
  const { isLoading: storeTokenDataLoading, isSuccess: storeTokenDataSuccess } = (0, import_wagmi2.useWaitForTransaction)({
    hash: storeTokenDataData == null ? void 0 : storeTokenDataData.hash
  });
  return {
    storeTokenDataConfig,
    storeTokenData,
    storeTokenDataLoading,
    storeTokenDataSuccess
  };
}

// src/hooks/useOverwriteTokenData.ts
var import_wagmi3 = require("wagmi");
function useOverwriteTokenData({
  press,
  data,
  prepareTxn
}) {
  const { config: overwriteTokenDataConfig } = (0, import_wagmi3.usePrepareContractWrite)({
    address: router,
    abi: routerAbi,
    functionName: "overwriteTokenData",
    args: [press, data],
    // chainId: optimismGoerli.id,
    // BigInt(0)
    value: BigInt(5e14),
    enabled: prepareTxn
  });
  const { data: overwriteTokenDataData, write: overwriteTokenData } = (0, import_wagmi3.useContractWrite)(overwriteTokenDataConfig);
  const {
    isLoading: overwriteTokenDataLoading,
    isSuccess: overwriteTokenDataSuccess
  } = (0, import_wagmi3.useWaitForTransaction)({
    hash: overwriteTokenDataData == null ? void 0 : overwriteTokenDataData.hash
  });
  return {
    overwriteTokenDataConfig,
    overwriteTokenData,
    overwriteTokenDataLoading,
    overwriteTokenDataSuccess
  };
}
// Annotate the CommonJS export names for ESM import in node:
0 && (module.exports = {
  useOverwriteTokenData,
  useSetup,
  useStoreTokenData
});
