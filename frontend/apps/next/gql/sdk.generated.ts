import { GraphQLClient } from 'graphql-request';
import { GraphQLClientRequestHeaders } from 'graphql-request/build/cjs/types';
import gql from 'graphql-tag';
export type Maybe<T> = T | null;
export type InputMaybe<T> = Maybe<T>;
export type Exact<T extends { [key: string]: unknown }> = { [K in keyof T]: T[K] };
export type MakeOptional<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]?: Maybe<T[SubKey]> };
export type MakeMaybe<T, K extends keyof T> = Omit<T, K> & { [SubKey in K]: Maybe<T[SubKey]> };
export type MakeEmpty<T extends { [key: string]: unknown }, K extends keyof T> = { [_ in K]?: never };
export type Incremental<T> = T | { [P in keyof T]?: P extends ' $fragmentName' | '__typename' ? T[P] : never };
/** All built-in and custom scalars, mapped to their actual values */
export type Scalars = {
  ID: { input: string; output: string; }
  String: { input: string; output: string; }
  Boolean: { input: boolean; output: boolean; }
  Int: { input: number; output: number; }
  Float: { input: number; output: number; }
  bigint: { input: any; output: any; }
  timestamp: { input: any; output: any; }
};

/** columns and relationships of "AP721" */
export type Ap721 = {
  __typename?: 'AP721';
  ap721: Scalars['String']['output'];
  createdAt: Scalars['bigint']['output'];
  factory: Scalars['String']['output'];
  logic: Scalars['String']['output'];
  owner: Scalars['String']['output'];
  renderer: Scalars['String']['output'];
  sender: Scalars['String']['output'];
  transactionHash: Scalars['String']['output'];
};

/** Boolean expression to filter rows from the table "AP721". All fields are combined with a logical 'AND'. */
export type Ap721_Bool_Exp = {
  _and?: InputMaybe<Array<Ap721_Bool_Exp>>;
  _not?: InputMaybe<Ap721_Bool_Exp>;
  _or?: InputMaybe<Array<Ap721_Bool_Exp>>;
  ap721?: InputMaybe<String_Comparison_Exp>;
  createdAt?: InputMaybe<Bigint_Comparison_Exp>;
  factory?: InputMaybe<String_Comparison_Exp>;
  logic?: InputMaybe<String_Comparison_Exp>;
  owner?: InputMaybe<String_Comparison_Exp>;
  renderer?: InputMaybe<String_Comparison_Exp>;
  sender?: InputMaybe<String_Comparison_Exp>;
  transactionHash?: InputMaybe<String_Comparison_Exp>;
};

/** Ordering options when selecting data from "AP721". */
export type Ap721_Order_By = {
  ap721?: InputMaybe<Order_By>;
  createdAt?: InputMaybe<Order_By>;
  factory?: InputMaybe<Order_By>;
  logic?: InputMaybe<Order_By>;
  owner?: InputMaybe<Order_By>;
  renderer?: InputMaybe<Order_By>;
  sender?: InputMaybe<Order_By>;
  transactionHash?: InputMaybe<Order_By>;
};

/** select columns of table "AP721" */
export enum Ap721_Select_Column {
  /** column name */
  Ap721 = 'ap721',
  /** column name */
  CreatedAt = 'createdAt',
  /** column name */
  Factory = 'factory',
  /** column name */
  Logic = 'logic',
  /** column name */
  Owner = 'owner',
  /** column name */
  Renderer = 'renderer',
  /** column name */
  Sender = 'sender',
  /** column name */
  TransactionHash = 'transactionHash'
}

/** Streaming cursor of the table "AP721" */
export type Ap721_Stream_Cursor_Input = {
  /** Stream column input with initial value */
  initial_value: Ap721_Stream_Cursor_Value_Input;
  /** cursor ordering */
  ordering?: InputMaybe<Cursor_Ordering>;
};

/** Initial value of the column from where the streaming should start */
export type Ap721_Stream_Cursor_Value_Input = {
  ap721?: InputMaybe<Scalars['String']['input']>;
  createdAt?: InputMaybe<Scalars['bigint']['input']>;
  factory?: InputMaybe<Scalars['String']['input']>;
  logic?: InputMaybe<Scalars['String']['input']>;
  owner?: InputMaybe<Scalars['String']['input']>;
  renderer?: InputMaybe<Scalars['String']['input']>;
  sender?: InputMaybe<Scalars['String']['input']>;
  transactionHash?: InputMaybe<Scalars['String']['input']>;
};

/** columns and relationships of "Arweave" */
export type Arweave = {
  __typename?: 'Arweave';
  link: Scalars['String']['output'];
  tableName: Scalars['String']['output'];
  timestamp: Scalars['timestamp']['output'];
};

/** Boolean expression to filter rows from the table "Arweave". All fields are combined with a logical 'AND'. */
export type Arweave_Bool_Exp = {
  _and?: InputMaybe<Array<Arweave_Bool_Exp>>;
  _not?: InputMaybe<Arweave_Bool_Exp>;
  _or?: InputMaybe<Array<Arweave_Bool_Exp>>;
  link?: InputMaybe<String_Comparison_Exp>;
  tableName?: InputMaybe<String_Comparison_Exp>;
  timestamp?: InputMaybe<Timestamp_Comparison_Exp>;
};

/** Ordering options when selecting data from "Arweave". */
export type Arweave_Order_By = {
  link?: InputMaybe<Order_By>;
  tableName?: InputMaybe<Order_By>;
  timestamp?: InputMaybe<Order_By>;
};

/** select columns of table "Arweave" */
export enum Arweave_Select_Column {
  /** column name */
  Link = 'link',
  /** column name */
  TableName = 'tableName',
  /** column name */
  Timestamp = 'timestamp'
}

/** Streaming cursor of the table "Arweave" */
export type Arweave_Stream_Cursor_Input = {
  /** Stream column input with initial value */
  initial_value: Arweave_Stream_Cursor_Value_Input;
  /** cursor ordering */
  ordering?: InputMaybe<Cursor_Ordering>;
};

/** Initial value of the column from where the streaming should start */
export type Arweave_Stream_Cursor_Value_Input = {
  link?: InputMaybe<Scalars['String']['input']>;
  tableName?: InputMaybe<Scalars['String']['input']>;
  timestamp?: InputMaybe<Scalars['timestamp']['input']>;
};

/** Boolean expression to compare columns of type "String". All fields are combined with logical 'AND'. */
export type String_Comparison_Exp = {
  _eq?: InputMaybe<Scalars['String']['input']>;
  _gt?: InputMaybe<Scalars['String']['input']>;
  _gte?: InputMaybe<Scalars['String']['input']>;
  /** does the column match the given case-insensitive pattern */
  _ilike?: InputMaybe<Scalars['String']['input']>;
  _in?: InputMaybe<Array<Scalars['String']['input']>>;
  /** does the column match the given POSIX regular expression, case insensitive */
  _iregex?: InputMaybe<Scalars['String']['input']>;
  _is_null?: InputMaybe<Scalars['Boolean']['input']>;
  /** does the column match the given pattern */
  _like?: InputMaybe<Scalars['String']['input']>;
  _lt?: InputMaybe<Scalars['String']['input']>;
  _lte?: InputMaybe<Scalars['String']['input']>;
  _neq?: InputMaybe<Scalars['String']['input']>;
  /** does the column NOT match the given case-insensitive pattern */
  _nilike?: InputMaybe<Scalars['String']['input']>;
  _nin?: InputMaybe<Array<Scalars['String']['input']>>;
  /** does the column NOT match the given POSIX regular expression, case insensitive */
  _niregex?: InputMaybe<Scalars['String']['input']>;
  /** does the column NOT match the given pattern */
  _nlike?: InputMaybe<Scalars['String']['input']>;
  /** does the column NOT match the given POSIX regular expression, case sensitive */
  _nregex?: InputMaybe<Scalars['String']['input']>;
  /** does the column NOT match the given SQL regular expression */
  _nsimilar?: InputMaybe<Scalars['String']['input']>;
  /** does the column match the given POSIX regular expression, case sensitive */
  _regex?: InputMaybe<Scalars['String']['input']>;
  /** does the column match the given SQL regular expression */
  _similar?: InputMaybe<Scalars['String']['input']>;
};

/** columns and relationships of "TokenStorage" */
export type TokenStorage = {
  __typename?: 'TokenStorage';
  ap721: Scalars['String']['output'];
  pointer: Scalars['String']['output'];
  tokenId: Scalars['bigint']['output'];
  transactionHash: Scalars['String']['output'];
  updatedAt: Scalars['bigint']['output'];
  updatedBy: Scalars['String']['output'];
};

/** Boolean expression to filter rows from the table "TokenStorage". All fields are combined with a logical 'AND'. */
export type TokenStorage_Bool_Exp = {
  _and?: InputMaybe<Array<TokenStorage_Bool_Exp>>;
  _not?: InputMaybe<TokenStorage_Bool_Exp>;
  _or?: InputMaybe<Array<TokenStorage_Bool_Exp>>;
  ap721?: InputMaybe<String_Comparison_Exp>;
  pointer?: InputMaybe<String_Comparison_Exp>;
  tokenId?: InputMaybe<Bigint_Comparison_Exp>;
  transactionHash?: InputMaybe<String_Comparison_Exp>;
  updatedAt?: InputMaybe<Bigint_Comparison_Exp>;
  updatedBy?: InputMaybe<String_Comparison_Exp>;
};

/** Ordering options when selecting data from "TokenStorage". */
export type TokenStorage_Order_By = {
  ap721?: InputMaybe<Order_By>;
  pointer?: InputMaybe<Order_By>;
  tokenId?: InputMaybe<Order_By>;
  transactionHash?: InputMaybe<Order_By>;
  updatedAt?: InputMaybe<Order_By>;
  updatedBy?: InputMaybe<Order_By>;
};

/** select columns of table "TokenStorage" */
export enum TokenStorage_Select_Column {
  /** column name */
  Ap721 = 'ap721',
  /** column name */
  Pointer = 'pointer',
  /** column name */
  TokenId = 'tokenId',
  /** column name */
  TransactionHash = 'transactionHash',
  /** column name */
  UpdatedAt = 'updatedAt',
  /** column name */
  UpdatedBy = 'updatedBy'
}

/** Streaming cursor of the table "TokenStorage" */
export type TokenStorage_Stream_Cursor_Input = {
  /** Stream column input with initial value */
  initial_value: TokenStorage_Stream_Cursor_Value_Input;
  /** cursor ordering */
  ordering?: InputMaybe<Cursor_Ordering>;
};

/** Initial value of the column from where the streaming should start */
export type TokenStorage_Stream_Cursor_Value_Input = {
  ap721?: InputMaybe<Scalars['String']['input']>;
  pointer?: InputMaybe<Scalars['String']['input']>;
  tokenId?: InputMaybe<Scalars['bigint']['input']>;
  transactionHash?: InputMaybe<Scalars['String']['input']>;
  updatedAt?: InputMaybe<Scalars['bigint']['input']>;
  updatedBy?: InputMaybe<Scalars['String']['input']>;
};

/** columns and relationships of "Transaction" */
export type Transaction = {
  __typename?: 'Transaction';
  createdAt: Scalars['bigint']['output'];
  eventType: Scalars['String']['output'];
  transactionHash: Scalars['String']['output'];
};

/** Boolean expression to filter rows from the table "Transaction". All fields are combined with a logical 'AND'. */
export type Transaction_Bool_Exp = {
  _and?: InputMaybe<Array<Transaction_Bool_Exp>>;
  _not?: InputMaybe<Transaction_Bool_Exp>;
  _or?: InputMaybe<Array<Transaction_Bool_Exp>>;
  createdAt?: InputMaybe<Bigint_Comparison_Exp>;
  eventType?: InputMaybe<String_Comparison_Exp>;
  transactionHash?: InputMaybe<String_Comparison_Exp>;
};

/** Ordering options when selecting data from "Transaction". */
export type Transaction_Order_By = {
  createdAt?: InputMaybe<Order_By>;
  eventType?: InputMaybe<Order_By>;
  transactionHash?: InputMaybe<Order_By>;
};

/** select columns of table "Transaction" */
export enum Transaction_Select_Column {
  /** column name */
  CreatedAt = 'createdAt',
  /** column name */
  EventType = 'eventType',
  /** column name */
  TransactionHash = 'transactionHash'
}

/** Streaming cursor of the table "Transaction" */
export type Transaction_Stream_Cursor_Input = {
  /** Stream column input with initial value */
  initial_value: Transaction_Stream_Cursor_Value_Input;
  /** cursor ordering */
  ordering?: InputMaybe<Cursor_Ordering>;
};

/** Initial value of the column from where the streaming should start */
export type Transaction_Stream_Cursor_Value_Input = {
  createdAt?: InputMaybe<Scalars['bigint']['input']>;
  eventType?: InputMaybe<Scalars['String']['input']>;
  transactionHash?: InputMaybe<Scalars['String']['input']>;
};

/** Boolean expression to compare columns of type "bigint". All fields are combined with logical 'AND'. */
export type Bigint_Comparison_Exp = {
  _eq?: InputMaybe<Scalars['bigint']['input']>;
  _gt?: InputMaybe<Scalars['bigint']['input']>;
  _gte?: InputMaybe<Scalars['bigint']['input']>;
  _in?: InputMaybe<Array<Scalars['bigint']['input']>>;
  _is_null?: InputMaybe<Scalars['Boolean']['input']>;
  _lt?: InputMaybe<Scalars['bigint']['input']>;
  _lte?: InputMaybe<Scalars['bigint']['input']>;
  _neq?: InputMaybe<Scalars['bigint']['input']>;
  _nin?: InputMaybe<Array<Scalars['bigint']['input']>>;
};

/** ordering argument of a cursor */
export enum Cursor_Ordering {
  /** ascending ordering of the cursor */
  Asc = 'ASC',
  /** descending ordering of the cursor */
  Desc = 'DESC'
}

/** column ordering options */
export enum Order_By {
  /** in ascending order, nulls last */
  Asc = 'asc',
  /** in ascending order, nulls first */
  AscNullsFirst = 'asc_nulls_first',
  /** in ascending order, nulls last */
  AscNullsLast = 'asc_nulls_last',
  /** in descending order, nulls first */
  Desc = 'desc',
  /** in descending order, nulls first */
  DescNullsFirst = 'desc_nulls_first',
  /** in descending order, nulls last */
  DescNullsLast = 'desc_nulls_last'
}
export type Query_Root = {
  __typename?: 'query_root';
  /** fetch data from the table: "AP721" */
  AP721: Array<Ap721>;
  /** fetch data from the table: "AP721" using primary key columns */
  AP721_by_pk?: Maybe<Ap721>;
  /** fetch data from the table: "Arweave" */
  Arweave: Array<Arweave>;
  /** fetch data from the table: "Arweave" using primary key columns */
  Arweave_by_pk?: Maybe<Arweave>;
  /** fetch data from the table: "TokenStorage" */
  TokenStorage: Array<TokenStorage>;
  /** fetch data from the table: "TokenStorage" using primary key columns */
  TokenStorage_by_pk?: Maybe<TokenStorage>;
  /** fetch data from the table: "Transaction" */
  Transaction: Array<Transaction>;
  /** fetch data from the table: "Transaction" using primary key columns */
  Transaction_by_pk?: Maybe<Transaction>;
};

export type Query_RootAp721Args = {
  distinct_on?: InputMaybe<Array<Ap721_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Ap721_Order_By>>;
  where?: InputMaybe<Ap721_Bool_Exp>;
};


export type Query_RootAp721_By_PkArgs = {
  ap721: Scalars['String']['input'];
};


export type Query_RootArweaveArgs = {
  distinct_on?: InputMaybe<Array<Arweave_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Arweave_Order_By>>;
  where?: InputMaybe<Arweave_Bool_Exp>;
};


export type Query_RootArweave_By_PkArgs = {
  link: Scalars['String']['input'];
};


export type Query_RootTokenStorageArgs = {
  distinct_on?: InputMaybe<Array<TokenStorage_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<TokenStorage_Order_By>>;
  where?: InputMaybe<TokenStorage_Bool_Exp>;
};


export type Query_RootTokenStorage_By_PkArgs = {
  ap721: Scalars['String']['input'];
  tokenId: Scalars['bigint']['input'];
};


export type Query_RootTransactionArgs = {
  distinct_on?: InputMaybe<Array<Transaction_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Transaction_Order_By>>;
  where?: InputMaybe<Transaction_Bool_Exp>;
};


export type Query_RootTransaction_By_PkArgs = {
  transactionHash: Scalars['String']['input'];
};

export type Subscription_Root = {
  __typename?: 'subscription_root';
  /** fetch data from the table: "AP721" */
  AP721: Array<Ap721>;
  /** fetch data from the table: "AP721" using primary key columns */
  AP721_by_pk?: Maybe<Ap721>;
  /** fetch data from the table in a streaming manner: "AP721" */
  AP721_stream: Array<Ap721>;
  /** fetch data from the table: "Arweave" */
  Arweave: Array<Arweave>;
  /** fetch data from the table: "Arweave" using primary key columns */
  Arweave_by_pk?: Maybe<Arweave>;
  /** fetch data from the table in a streaming manner: "Arweave" */
  Arweave_stream: Array<Arweave>;
  /** fetch data from the table: "TokenStorage" */
  TokenStorage: Array<TokenStorage>;
  /** fetch data from the table: "TokenStorage" using primary key columns */
  TokenStorage_by_pk?: Maybe<TokenStorage>;
  /** fetch data from the table in a streaming manner: "TokenStorage" */
  TokenStorage_stream: Array<TokenStorage>;
  /** fetch data from the table: "Transaction" */
  Transaction: Array<Transaction>;
  /** fetch data from the table: "Transaction" using primary key columns */
  Transaction_by_pk?: Maybe<Transaction>;
  /** fetch data from the table in a streaming manner: "Transaction" */
  Transaction_stream: Array<Transaction>;
};


export type Subscription_RootAp721Args = {
  distinct_on?: InputMaybe<Array<Ap721_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Ap721_Order_By>>;
  where?: InputMaybe<Ap721_Bool_Exp>;
};


export type Subscription_RootAp721_By_PkArgs = {
  ap721: Scalars['String']['input'];
};


export type Subscription_RootAp721_StreamArgs = {
  batch_size: Scalars['Int']['input'];
  cursor: Array<InputMaybe<Ap721_Stream_Cursor_Input>>;
  where?: InputMaybe<Ap721_Bool_Exp>;
};


export type Subscription_RootArweaveArgs = {
  distinct_on?: InputMaybe<Array<Arweave_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Arweave_Order_By>>;
  where?: InputMaybe<Arweave_Bool_Exp>;
};


export type Subscription_RootArweave_By_PkArgs = {
  link: Scalars['String']['input'];
};


export type Subscription_RootArweave_StreamArgs = {
  batch_size: Scalars['Int']['input'];
  cursor: Array<InputMaybe<Arweave_Stream_Cursor_Input>>;
  where?: InputMaybe<Arweave_Bool_Exp>;
};


export type Subscription_RootTokenStorageArgs = {
  distinct_on?: InputMaybe<Array<TokenStorage_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<TokenStorage_Order_By>>;
  where?: InputMaybe<TokenStorage_Bool_Exp>;
};


export type Subscription_RootTokenStorage_By_PkArgs = {
  ap721: Scalars['String']['input'];
  tokenId: Scalars['bigint']['input'];
};


export type Subscription_RootTokenStorage_StreamArgs = {
  batch_size: Scalars['Int']['input'];
  cursor: Array<InputMaybe<TokenStorage_Stream_Cursor_Input>>;
  where?: InputMaybe<TokenStorage_Bool_Exp>;
};


export type Subscription_RootTransactionArgs = {
  distinct_on?: InputMaybe<Array<Transaction_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<Transaction_Order_By>>;
  where?: InputMaybe<Transaction_Bool_Exp>;
};


export type Subscription_RootTransaction_By_PkArgs = {
  transactionHash: Scalars['String']['input'];
};


export type Subscription_RootTransaction_StreamArgs = {
  batch_size: Scalars['Int']['input'];
  cursor: Array<InputMaybe<Transaction_Stream_Cursor_Input>>;
  where?: InputMaybe<Transaction_Bool_Exp>;
};

/** Boolean expression to compare columns of type "timestamp". All fields are combined with logical 'AND'. */
export type Timestamp_Comparison_Exp = {
  _eq?: InputMaybe<Scalars['timestamp']['input']>;
  _gt?: InputMaybe<Scalars['timestamp']['input']>;
  _gte?: InputMaybe<Scalars['timestamp']['input']>;
  _in?: InputMaybe<Array<Scalars['timestamp']['input']>>;
  _is_null?: InputMaybe<Scalars['Boolean']['input']>;
  _lt?: InputMaybe<Scalars['timestamp']['input']>;
  _lte?: InputMaybe<Scalars['timestamp']['input']>;
  _neq?: InputMaybe<Scalars['timestamp']['input']>;
  _nin?: InputMaybe<Array<Scalars['timestamp']['input']>>;
};

export type RecentTransactionsQueryVariables = Exact<{ [key: string]: never; }>;

export type RecentTransactionsQuery = { __typename?: 'query_root', Transaction: Array<{ __typename?: 'Transaction', createdAt: any, eventType: string, transactionHash: string }> };


export const RecentTransactionsDocument = gql`
    query RecentTransactions {
  Transaction(limit: 10, order_by: {createdAt: desc}) {
    createdAt
    eventType
    transactionHash
  }
}
    `;

export type RecentArweaveTransactionsQuery = {
      __typename?: 'query_root';
      Arweave: Array<{
        tableName: string;
        link: string;
      }>;
    };
    
export const RecentArweaveTransactionsDocument = gql`
      query RecentArweaveTransactions {
        Arweave(limit: 3, order_by: { timestamp: asc }) {
          tableName
          link
        }
      }
    `;
    
export type SdkFunctionWrapper = <T>(
      action: (requestHeaders?: Record<string, string>) => Promise<T>,
      operationName: string,
      operationType?: string
    ) => Promise<T>;
    
    const defaultWrapper: SdkFunctionWrapper = (action, _operationName, _operationType) => action();
    
export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
      return {
        RecentTransactions(
          variables?: RecentTransactionsQueryVariables,
          requestHeaders?: GraphQLClientRequestHeaders
        ): Promise<RecentTransactionsQuery> {
          return withWrapper((wrappedRequestHeaders) =>
            client.request<RecentTransactionsQuery>(
              RecentTransactionsDocument,
              variables,
              { ...requestHeaders, ...wrappedRequestHeaders }
            ),
            'RecentTransactions',
            'query'
          );
        },
    
        RecentArweaveTransactions(
          requestHeaders?: GraphQLClientRequestHeaders
        ): Promise<RecentArweaveTransactionsQuery> {
          return withWrapper((wrappedRequestHeaders) =>
            client.request<RecentArweaveTransactionsQuery>(
              RecentArweaveTransactionsDocument,
              undefined, // No variables for this query
              { ...requestHeaders, ...wrappedRequestHeaders }
            ),
            'RecentArweaveTransactions',
            'query'
          );
        },
      };
    }
    
export type Sdk = ReturnType<typeof getSdk>;