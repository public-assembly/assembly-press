import { gql } from 'graphql-request'

export const recentTransactionsQuery = gql`query RecentTransactions {
    Transaction(limit: 8, order_by: {createdAt: desc}) {
      createdAt
      eventType
      transactionHash
    }
  }`
