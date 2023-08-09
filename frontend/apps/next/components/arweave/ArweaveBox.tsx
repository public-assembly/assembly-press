import {
  recentTransactions,
  type Transaction,
} from 'gql/requests/recentTransactions';
import { Caption, Flex, Grid, BodySmall, Debug } from '../base';
import { cn } from '@/utils/cn';

type TransactionFieldProps = {
  value:
    | Transaction['createdAt']
    | Transaction['eventType']
    | Transaction['transactionHash'];
  className?: string;
};

type TransactionHashProps = TransactionFieldProps;

type EventTypeProps = {
  value: Transaction['eventType'];
  className?: string;
};

type TransactionComponentProps = {
  transaction: Transaction;
  className?: string;
};

type TransactionsTableProps = {
  className?: string;
};

const EventType = ({ value, className }: EventTypeProps) => (
  <Flex
    className={cn(
      value === 'DataStored' ||
        value === 'DataRemoved' ||
        value === 'DataOverwritten'
        ? 'border-heliotrope'
        : value === 'LogicUpdated' || value === 'RendererUpdated'
        ? 'border-malachite'
        : 'border-picton-blue',
      'uppercase border rounded-[2px] px-2 py-[2px] justify-center items-center w-fit'
    )}
  >
    <Caption className='text-platinum'>
      <p>{value.toString()}</p>
    </Caption>
  </Flex>
);

const TransactionField = ({ value, className }: TransactionFieldProps) => (
  <Caption className='text-platinum'>
    <p>{value.toString()}</p>
  </Caption>
);

const TransactionHash = ({ value, className }: TransactionHashProps) => (
  <Flex className='px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
    <BodySmall className='text-dark-gray'>{value.toString()}</BodySmall>
  </Flex>
);

const TransactionComponent = ({
  transaction,
  className,
}: TransactionComponentProps) => (
  <Grid className='grid-cols-3 items-center my-2'>
    <EventType value={transaction.eventType} />
    <TransactionField value={transaction.createdAt} />
    <TransactionHash value={transaction.transactionHash.slice(0, 10)} />
  </Grid>
);

export const ArweaveBox = async ({
  className,
}: TransactionsTableProps) => {
  const Transaction = await recentTransactions();

  return (
    <Flex className='flex-col'>
      {Transaction.map((transaction) => (
        <TransactionComponent
          key={transaction.transactionHash}
          transaction={transaction}
        />
      ))}
    </Flex>
  );
};
