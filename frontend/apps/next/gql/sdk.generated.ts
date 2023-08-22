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

/** columns and relationships of "RawTransaction" */
export type RawTransaction = {
  __typename?: 'RawTransaction';
  createdAt: Scalars['bigint']['output'];
  eventType: Scalars['String']['output'];
  transactionHash: Scalars['String']['output'];
};

/** Boolean expression to filter rows from the table "RawTransaction". All fields are combined with a logical 'AND'. */
export type RawTransaction_Bool_Exp = {
  _and?: InputMaybe<Array<RawTransaction_Bool_Exp>>;
  _not?: InputMaybe<RawTransaction_Bool_Exp>;
  _or?: InputMaybe<Array<RawTransaction_Bool_Exp>>;
  createdAt?: InputMaybe<Bigint_Comparison_Exp>;
  eventType?: InputMaybe<String_Comparison_Exp>;
  transactionHash?: InputMaybe<String_Comparison_Exp>;
};

/** Ordering options when selecting data from "RawTransaction". */
export type RawTransaction_Order_By = {
  createdAt?: InputMaybe<Order_By>;
  eventType?: InputMaybe<Order_By>;
  transactionHash?: InputMaybe<Order_By>;
};

/** select columns of table "RawTransaction" */
export enum RawTransaction_Select_Column {
  /** column name */
  CreatedAt = 'createdAt',
  /** column name */
  EventType = 'eventType',
  /** column name */
  TransactionHash = 'transactionHash'
}

/** Streaming cursor of the table "RawTransaction" */
export type RawTransaction_Stream_Cursor_Input = {
  /** Stream column input with initial value */
  initial_value: RawTransaction_Stream_Cursor_Value_Input;
  /** cursor ordering */
  ordering?: InputMaybe<Cursor_Ordering>;
};

/** Initial value of the column from where the streaming should start */
export type RawTransaction_Stream_Cursor_Value_Input = {
  createdAt?: InputMaybe<Scalars['bigint']['input']>;
  eventType?: InputMaybe<Scalars['String']['input']>;
  transactionHash?: InputMaybe<Scalars['String']['input']>;
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
  /** fetch data from the table: "Arweave" */
  Arweave: Array<Arweave>;
  /** fetch data from the table: "Arweave" using primary key columns */
  Arweave_by_pk?: Maybe<Arweave>;
  /** fetch data from the table: "RawTransaction" */
  RawTransaction: Array<RawTransaction>;
  /** fetch data from the table: "RawTransaction" using primary key columns */
  RawTransaction_by_pk?: Maybe<RawTransaction>;
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


export type Query_RootRawTransactionArgs = {
  distinct_on?: InputMaybe<Array<RawTransaction_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<RawTransaction_Order_By>>;
  where?: InputMaybe<RawTransaction_Bool_Exp>;
};


export type Query_RootRawTransaction_By_PkArgs = {
  transactionHash: Scalars['String']['input'];
};

export type Subscription_Root = {
  __typename?: 'subscription_root';
  /** fetch data from the table: "Arweave" */
  Arweave: Array<Arweave>;
  /** fetch data from the table: "Arweave" using primary key columns */
  Arweave_by_pk?: Maybe<Arweave>;
  /** fetch data from the table in a streaming manner: "Arweave" */
  Arweave_stream: Array<Arweave>;
  /** fetch data from the table: "RawTransaction" */
  RawTransaction: Array<RawTransaction>;
  /** fetch data from the table: "RawTransaction" using primary key columns */
  RawTransaction_by_pk?: Maybe<RawTransaction>;
  /** fetch data from the table in a streaming manner: "RawTransaction" */
  RawTransaction_stream: Array<RawTransaction>;
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


export type Subscription_RootRawTransactionArgs = {
  distinct_on?: InputMaybe<Array<RawTransaction_Select_Column>>;
  limit?: InputMaybe<Scalars['Int']['input']>;
  offset?: InputMaybe<Scalars['Int']['input']>;
  order_by?: InputMaybe<Array<RawTransaction_Order_By>>;
  where?: InputMaybe<RawTransaction_Bool_Exp>;
};


export type Subscription_RootRawTransaction_By_PkArgs = {
  transactionHash: Scalars['String']['input'];
};


export type Subscription_RootRawTransaction_StreamArgs = {
  batch_size: Scalars['Int']['input'];
  cursor: Array<InputMaybe<RawTransaction_Stream_Cursor_Input>>;
  where?: InputMaybe<RawTransaction_Bool_Exp>;
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

export type RecentArweaveTransactionsQueryVariables = Exact<{ [key: string]: never; }>;


export type RecentArweaveTransactionsQuery = { __typename?: 'query_root', Arweave: Array<{ __typename?: 'Arweave', tableName: string, link: string }> };

export type RecentRawTransactionsQueryVariables = Exact<{ [key: string]: never; }>;


export type RecentRawTransactionsQuery = { __typename?: 'query_root', RawTransaction: Array<{ __typename?: 'RawTransaction', createdAt: any, eventType: string, transactionHash: string }> };


export const RecentArweaveTransactionsDocument = gql`
    query RecentArweaveTransactions {
  Arweave(limit: 3, order_by: {timestamp: desc}) {
    tableName
    link
  }
}
    `;
export const RecentRawTransactionsDocument = gql`
    query RecentRawTransactions {
  RawTransaction(limit: 8, order_by: {createdAt: desc}) {
    createdAt
    eventType
    transactionHash
  }
}
    `;

export type SdkFunctionWrapper = <T>(action: (requestHeaders?:Record<string, string>) => Promise<T>, operationName: string, operationType?: string) => Promise<T>;


const defaultWrapper: SdkFunctionWrapper = (action, _operationName, _operationType) => action();

export function getSdk(client: GraphQLClient, withWrapper: SdkFunctionWrapper = defaultWrapper) {
  return {
    RecentArweaveTransactions(variables?: RecentArweaveTransactionsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<RecentArweaveTransactionsQuery> {
      return withWrapper((wrappedRequestHeaders) => client.request<RecentArweaveTransactionsQuery>(RecentArweaveTransactionsDocument, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'RecentArweaveTransactions', 'query');
    },
    RecentRawTransactions(variables?: RecentRawTransactionsQueryVariables, requestHeaders?: GraphQLClientRequestHeaders): Promise<RecentRawTransactionsQuery> {
      return withWrapper((wrappedRequestHeaders) => client.request<RecentRawTransactionsQuery>(RecentRawTransactionsDocument, variables, {...requestHeaders, ...wrappedRequestHeaders}), 'RecentRawTransactions', 'query');
    }
  };
}
export type Sdk = ReturnType<typeof getSdk>;