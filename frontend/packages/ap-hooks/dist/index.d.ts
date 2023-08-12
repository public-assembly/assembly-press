import { Hex, Hash } from 'viem';
import { PrepareWriteContractResult } from 'wagmi/actions';

interface StoreProps {
    database: Hex;
    target: Hex;
    quantity: bigint;
    data: Hash;
    prepareTxn: boolean;
}
declare function useStore({ database, target, quantity, data, prepareTxn }: StoreProps): {
    store: (() => void) | undefined;
    storeLoading: boolean;
    storeSuccess: boolean;
};

interface OverwriteProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
    data: Hash[];
    prepareTxn: boolean;
}
declare function useOverwrite({ database, target, tokenIds, data, prepareTxn }: OverwriteProps): {
    overwrite: (() => void) | undefined;
    overwriteLoading: boolean;
    overwriteSuccess: boolean;
};

interface RemoveProps {
    database: Hex;
    target: Hex;
    tokenIds: bigint[];
    prepareTxn: boolean;
}
declare function useRemove({ database, target, tokenIds, prepareTxn }: RemoveProps): {
    remove: (() => void) | undefined;
    removeLoading: boolean;
    removeSuccess: boolean;
};

interface SetLogicProps {
    database: Hex;
    target: Hex;
    logic: Hex;
    logicInit: Hash;
    prepareTxn: boolean;
}
declare function useSetLogic({ database, target, logic, logicInit, prepareTxn }: SetLogicProps): {
    setLogic: (() => void) | undefined;
    setLogicLoading: boolean;
    setLogicSuccess: boolean;
};

interface SetRendererProps {
    database: Hex;
    target: Hex;
    renderer: Hex;
    rendererInit: Hash;
    prepareTxn: boolean;
}
declare function useSetRenderer({ database, target, renderer, rendererInit, prepareTxn }: SetRendererProps): {
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
    prepareTxn: boolean;
}

declare function useSetupAP721({ database, initialOwner, databaseInit, factory, factoryInit, prepareTxn, }: SetupAP721Props): {
    setupAP721Config: PrepareWriteContractResult<readonly [{
        readonly inputs: readonly [{
            readonly internalType: "uint256";
            readonly name: "_size";
            readonly type: "uint256";
        }, {
            readonly internalType: "uint256";
            readonly name: "_start";
            readonly type: "uint256";
        }, {
            readonly internalType: "uint256";
            readonly name: "_end";
            readonly type: "uint256";
        }];
        readonly name: "InvalidCodeAtRange";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "Invalid_Input_Length";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "No_Overwrite_Access";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "No_Remove_Access";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "No_Settings_Access";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "No_Store_Access";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "Target_Not_Initialized";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "Token_Does_Not_Exist";
        readonly type: "error";
    }, {
        readonly inputs: readonly [];
        readonly name: "WriteError";
        readonly type: "error";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }, {
            readonly indexed: false;
            readonly internalType: "address";
            readonly name: "pointer";
            readonly type: "address";
        }];
        readonly name: "DataOverwritten";
        readonly type: "event";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }];
        readonly name: "DataRemoved";
        readonly type: "event";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }, {
            readonly indexed: false;
            readonly internalType: "address";
            readonly name: "pointer";
            readonly type: "address";
        }];
        readonly name: "DataStored";
        readonly type: "event";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "logic";
            readonly type: "address";
        }];
        readonly name: "LogicUpdated";
        readonly type: "event";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "renderer";
            readonly type: "address";
        }];
        readonly name: "RendererUpdated";
        readonly type: "event";
    }, {
        readonly anonymous: false;
        readonly inputs: readonly [{
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "ap721";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly indexed: true;
            readonly internalType: "address";
            readonly name: "initialOwner";
            readonly type: "address";
        }, {
            readonly indexed: false;
            readonly internalType: "address";
            readonly name: "logic";
            readonly type: "address";
        }, {
            readonly indexed: false;
            readonly internalType: "address";
            readonly name: "renderer";
            readonly type: "address";
        }, {
            readonly indexed: false;
            readonly internalType: "address";
            readonly name: "factory";
            readonly type: "address";
        }];
        readonly name: "SetupAP721";
        readonly type: "event";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }];
        readonly name: "ap721Settings";
        readonly outputs: readonly [{
            readonly internalType: "uint256";
            readonly name: "storageCounter";
            readonly type: "uint256";
        }, {
            readonly internalType: "address";
            readonly name: "logic";
            readonly type: "address";
        }, {
            readonly internalType: "uint8";
            readonly name: "initialized";
            readonly type: "uint8";
        }, {
            readonly internalType: "address";
            readonly name: "renderer";
            readonly type: "address";
        }, {
            readonly components: readonly [{
                readonly internalType: "address";
                readonly name: "fundsRecipient";
                readonly type: "address";
            }, {
                readonly internalType: "uint16";
                readonly name: "royaltyBPS";
                readonly type: "uint16";
            }, {
                readonly internalType: "bool";
                readonly name: "transferable";
                readonly type: "bool";
            }];
            readonly internalType: "struct IAP721Database.AP721Config";
            readonly name: "ap721Config";
            readonly type: "tuple";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }];
        readonly name: "canEditSettings";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "access";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }];
        readonly name: "canOverwrite";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "access";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }];
        readonly name: "canRemove";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "access";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "sender";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "quantity";
            readonly type: "uint256";
        }];
        readonly name: "canStore";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "access";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [];
        readonly name: "contractURI";
        readonly outputs: readonly [{
            readonly internalType: "string";
            readonly name: "uri";
            readonly type: "string";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }];
        readonly name: "getSettings";
        readonly outputs: readonly [{
            readonly components: readonly [{
                readonly internalType: "uint256";
                readonly name: "storageCounter";
                readonly type: "uint256";
            }, {
                readonly internalType: "address";
                readonly name: "logic";
                readonly type: "address";
            }, {
                readonly internalType: "uint8";
                readonly name: "initialized";
                readonly type: "uint8";
            }, {
                readonly internalType: "address";
                readonly name: "renderer";
                readonly type: "address";
            }, {
                readonly components: readonly [{
                    readonly internalType: "address";
                    readonly name: "fundsRecipient";
                    readonly type: "address";
                }, {
                    readonly internalType: "uint16";
                    readonly name: "royaltyBPS";
                    readonly type: "uint16";
                }, {
                    readonly internalType: "bool";
                    readonly name: "transferable";
                    readonly type: "bool";
                }];
                readonly internalType: "struct IAP721Database.AP721Config";
                readonly name: "ap721Config";
                readonly type: "tuple";
            }];
            readonly internalType: "struct IAP721Database.Settings";
            readonly name: "";
            readonly type: "tuple";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }];
        readonly name: "getTransferable";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }];
        readonly name: "isInitialized";
        readonly outputs: readonly [{
            readonly internalType: "bool";
            readonly name: "initialized";
            readonly type: "bool";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "uint256[]";
            readonly name: "tokenIds";
            readonly type: "uint256[]";
        }, {
            readonly internalType: "bytes[]";
            readonly name: "data";
            readonly type: "bytes[]";
        }];
        readonly name: "overwrite";
        readonly outputs: readonly [];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }];
        readonly name: "readAllData";
        readonly outputs: readonly [{
            readonly internalType: "bytes[]";
            readonly name: "allData";
            readonly type: "bytes[]";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }];
        readonly name: "readData";
        readonly outputs: readonly [{
            readonly internalType: "bytes";
            readonly name: "data";
            readonly type: "bytes";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "uint256[]";
            readonly name: "tokenIds";
            readonly type: "uint256[]";
        }];
        readonly name: "remove";
        readonly outputs: readonly [];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "logic";
            readonly type: "address";
        }, {
            readonly internalType: "bytes";
            readonly name: "logicInit";
            readonly type: "bytes";
        }];
        readonly name: "setLogic";
        readonly outputs: readonly [];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "address";
            readonly name: "renderer";
            readonly type: "address";
        }, {
            readonly internalType: "bytes";
            readonly name: "rendererInit";
            readonly type: "bytes";
        }];
        readonly name: "setRenderer";
        readonly outputs: readonly [];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "initialOwner";
            readonly type: "address";
        }, {
            readonly internalType: "bytes";
            readonly name: "databaseInit";
            readonly type: "bytes";
        }, {
            readonly internalType: "address";
            readonly name: "factory";
            readonly type: "address";
        }, {
            readonly internalType: "bytes";
            readonly name: "factoryInit";
            readonly type: "bytes";
        }];
        readonly name: "setupAP721";
        readonly outputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "target";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "quantity";
            readonly type: "uint256";
        }, {
            readonly internalType: "bytes";
            readonly name: "data";
            readonly type: "bytes";
        }];
        readonly name: "store";
        readonly outputs: readonly [];
        readonly stateMutability: "nonpayable";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }, {
            readonly internalType: "uint256";
            readonly name: "";
            readonly type: "uint256";
        }];
        readonly name: "tokenData";
        readonly outputs: readonly [{
            readonly internalType: "address";
            readonly name: "";
            readonly type: "address";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }, {
        readonly inputs: readonly [{
            readonly internalType: "uint256";
            readonly name: "tokenId";
            readonly type: "uint256";
        }];
        readonly name: "tokenURI";
        readonly outputs: readonly [{
            readonly internalType: "string";
            readonly name: "uri";
            readonly type: "string";
        }];
        readonly stateMutability: "view";
        readonly type: "function";
    }], "setupAP721", 420>;
    setupAP721: (() => void) | undefined;
    setupAP721Loading: boolean;
    setupAP721Success: boolean;
};

export { useOverwrite, useRemove, useSetLogic, useSetRenderer, useSetupAP721, useStore };
