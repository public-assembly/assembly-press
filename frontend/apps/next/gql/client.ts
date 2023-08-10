import { GraphQLClient } from 'graphql-request'
import { getSdk } from './sdk.generated'

const client = new GraphQLClient('https://striking-possum-76.hasura.app/v1/graphql', {
  headers: {
    'Content-Type': 'application/json',
    'x-hasura-admin-secret': 'mI8pBnqi8ojlMcpfDF8bxrAr5HbWh4uNv5UZLb0lXnWfNqDFRzmuF7q85A63lof8'
  },
})

const sdk = getSdk(client)

export default sdk