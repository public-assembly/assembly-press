import gql from 'graphql-tag'

export const NEW_TRANSACTIONS_QUERY = gql`
  query NewTransactions($owner: String!) {
    transactions(
      owners: [$owner]
      tags: [
        { name: "Content-Type", values: ["application/json"] }
        {
          name: "Database Events - Chain: ${process.env.CHAIN_ID} v0.1"
          values: [
            "SetupAP721"
            "DataStored"
            "DataRemoved"
            "DataOverwritten"
            "LogicUpdated"
            "RendererUpdated"
          ]
        }
      ]
      order: ASC
    ) {
      edges {
        node {
          id
          address
          tags {
            name
            value
          }
        }
      }
    }
  }
`
