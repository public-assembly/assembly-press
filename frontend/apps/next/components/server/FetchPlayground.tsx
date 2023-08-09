import { recentTransactionsOverWebsockets } from 'gql/requests/recentTransactionsOverWebsockets';

export const FetchPlayground = async () => {
  const value = await recentTransactionsOverWebsockets();

  return <div className='text-platinum text-xl'>{JSON.stringify(value)}</div>;
};
