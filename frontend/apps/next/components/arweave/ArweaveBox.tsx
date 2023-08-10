import { recentArweaveTransactions, Arweave } from 'gql/requests/recentArweave';
import { Caption, Flex, Grid, BodySmall } from '../base';

type ArweaveFieldProps = {
  value: Arweave['tableName'] | Arweave['link'];
  className?: string;
};

const TableNameField = ({ value }: ArweaveFieldProps) => (
  <Caption className='text-platinum'>
    <p>{value.toString()}</p>
  </Caption>
);

const LinkField = ({ value }: ArweaveFieldProps) => (
  <Flex className='px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
    <a 
      href={value.toString()} 
      target="_blank" 
      rel="noopener noreferrer" 
      className='text-dark-gray hover:underline whitespace-nowrap' 
    >
      <BodySmall>{value.toString()}</BodySmall>
    </a>
  </Flex>
);

type ArweaveComponentProps = {
  arweave: Arweave;
  className?: string;
};

const ArweaveComponent = ({ arweave }: ArweaveComponentProps) => (
  <Grid className='grid-cols-1 md:grid-cols-3 items-center my-3'>
    <TableNameField value={arweave.tableName} className='mt-1 md:mt-0' />
    <LinkField value={arweave.link} className='mt-1 md:mt-0' />
  </Grid>
);
type ArweaveBoxProps = {
  className?: string;
};

export const ArweaveBox = async ({ className }: ArweaveBoxProps) => {
  const arweaveData = await recentArweaveTransactions();

  if (!arweaveData) return null; 

  return (
    <Flex className='flex-col'>
      {arweaveData.map((arweave) => (
        <ArweaveComponent key={arweave.link} arweave={arweave} />
      ))}
    </Flex>
  );
};
