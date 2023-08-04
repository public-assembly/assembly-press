export const createBundlrTags = (tableName: string) => {
  const tags = [
    { name: 'Content-Type', value: 'application/json' },
    { name: `Database Events - ${process.env.CHAIN_ID} v0.1`, value: `${tableName}` },
  ];
  
  return tags;
};
