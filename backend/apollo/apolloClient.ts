import ApolloClient from 'apollo-boost'

export const apolloClient = new ApolloClient({
  uri:
    process.env.NODE_ENV === 'production'
      ? 'http://node1.bundlr.network/graphql'
      : 'https://devnet.bundlr.network/graphql',
})
