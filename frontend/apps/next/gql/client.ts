import { GraphQLClient } from 'graphql-request'
import { getSdk } from './sdk.generated'

const client = new GraphQLClient('https://striking-possum-76.hasura.app/v1/graphql', {
  headers: {
    'Content-Type': 'application/json',
  },
})

const sdk = getSdk(client)

export default sdk