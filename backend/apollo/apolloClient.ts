import { HttpLink, ApolloClient, InMemoryCache } from 'apollo-boost'
import fetch from 'cross-fetch'

export const apolloClient = new ApolloClient({
  cache: new InMemoryCache(),
  link: new HttpLink({
    uri:
      process.env.NODE_ENV === 'production'
        ? 'http://node1.bundlr.network/graphql'
        : 'https://devnet.bundlr.network/graphql',
    fetch,
  }),
})
