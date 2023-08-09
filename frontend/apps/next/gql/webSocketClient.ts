import { createClient } from 'graphql-ws'

export const webSocketClient = createClient({
  url: 'wss://ap-op-goerli.hasura.app/v1/graphql',
  connectionParams: {
    headers: {
      'Sec-WebSocket-Protocol': 'graphql-ws',
    },
  },
})
