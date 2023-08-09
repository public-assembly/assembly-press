import { webSocketClient } from '../webSocketClient'
import { recentTransactionsQuery } from '../queries/recentTransactionsQuery'

export const recentTransactionsOverWebsockets = async () => {
  //   const query = webSocketClient.iterate({
  //     query: recentTransactionsQuery,
  //   })

  //   try {
  //     const { value } = await query.next()
  //     // console.log('Response value:', value)
  //     console.dir(value, { depth: null })
  //     return value
  //   } catch (err) {
  //     console.log(err)
  //   }

  const result = await new Promise((resolve, reject) => {
    let result
    webSocketClient.subscribe(
      {
        query: recentTransactionsQuery,
      },
      {
        // rome-ignore lint: 'let result equal data'
        next: (data) => (result = data),
        error: reject,
        complete: () => resolve(result),
      },
    )
  })
  console.dir(result, { depth: null })
}
