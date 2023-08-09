import sdk from '../client';

export interface Arweave {
  tableName: string;
  link: string;
};

export const recentArweaveTransactions = async (): Promise<Arweave[] | undefined> => {

  const { Arweave } = await sdk.RecentArweaveTransactions();

  return Arweave;
};