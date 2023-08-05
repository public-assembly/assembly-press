import gql from 'graphql-tag'

// query to get the details of the last event with a given name
export const LAST_EVENT_QUERY = gql`
  query LastEvent($fundingAddress: String!) {
    transactions(
      owners: [$fundingAddress]
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
      order: DESC
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
