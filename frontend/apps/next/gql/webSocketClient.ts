import { createClient } from 'graphql-ws'

export const webSocketClient = createClient({
  url: 'wss://https://striking-possum-76.hasura.app/v1/graphql',
  connectionParams: {
    headers: {
      'Sec-WebSocket-Protocol': 'graphql-ws',
    },
  },
})
