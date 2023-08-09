'use client';

import {
  recentTransactions,
  type Transaction,
} from 'gql/requests/recentTransactions';
import { useEffect, useState } from 'react';
import { Caption, Flex, Grid, Debug, BodySmall, CaptionLarge } from '../base';
import { cn } from '@/utils/cn';

type TransactionFieldProps = {
  transactions:
    | Transaction['createdAt']
    | Transaction['eventType']
    | Transaction['transactionHash'];
  className?: string;
};

type TransactionHashProps = TransactionFieldProps;

type EventTypeProps = {
  transactions: Transaction['eventType'];
  className?: string;
};

type TransactionComponentProps = {
  transaction: Transaction;
  className?: string;
};

type TransactionsTableProps = {
  className?: string;
};

const EventType = ({ transactions, className }: EventTypeProps) => (
  <Flex
    className={cn(
      transactions === 'DataStored' ||
        transactions === 'DataRemoved' ||
        transactions === 'DataOverwritten'
        ? 'border-heliotrope'
        : transactions === 'LogicUpdated' || transactions === 'RendererUpdated'
        ? 'border-malachite'
        : 'border-picton-blue',
      'border rounded-[2px] px-2 py-[2px] justify-center items-center w-[150px]'
    )}
  >
    <Caption className='text-platinum'>
      <p>{transactions.toString()}</p>
    </Caption>
  </Flex>
);

const TransactionField = ({
  transactions,
  className,
}: TransactionFieldProps) => (
  <CaptionLarge className='text-platinum'>
    <p>{transactions.toString()}</p>
  </CaptionLarge>
);

const TransactionHash = ({ transactions, className }: TransactionHashProps) => (
  <Flex className='px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
    <BodySmall className='text-dark-gray'>{transactions.toString()}</BodySmall>
  </Flex>
);

const TransactionComponent = ({
  transaction,
  className,
}: TransactionComponentProps) => (
  <Grid className='grid-cols-3 items-center my-2'>
    <EventType transactions={transaction.eventType} />
    <Flex className='justify-center'>
      <TransactionField transactions={transaction.createdAt} />
    </Flex>
    <Flex className='justify-end'>
      <TransactionHash
        transactions={transaction.transactionHash.slice(0, 10)}
      />
    </Flex>
  </Grid>
);

const TransactionsTableSkeleton = ({ className }: TransactionsTableProps) => {
  return (
    <div className='col-start-1 col-end-2 row-start-2 row-end-3'>
      <div className='border border-arsenic w-full h-full rounded-xl animate-pulse'>
        {}
      </div>
    </div>
  );
};

export const TransactionsTable = ({ className }: TransactionsTableProps) => {
  const [transactions, setTransactions] = useState<Transaction[]>();

  useEffect(() => {
    (async () => {
      try {
        const transactions = await recentTransactions();
        setTransactions(transactions);
      } catch (err) {
        console.log('Error... ', err);
      }
    })();
  }, [transactions]);

  if (!transactions) return <TransactionsTableSkeleton />;
  return (
    <Flex className='flex-col w-full content-between border border-arsenic rounded-xl px-6 py-3'>
      {/* Table Column Labels */}
      {/* <Grid className='grid-cols-3 items-center my-2'>
        <BodySmall className='text-platinum'>Event Name</BodySmall>
        <Flex className='justify-center'>
          <BodySmall className='text-platinum'>Block Number</BodySmall>
        </Flex>
        <Flex className='justify-end'>
          <BodySmall className='text-platinum'>Transaction Hash</BodySmall>
        </Flex>
      </Grid> */}
      {transactions.map((transaction) => (
        <TransactionComponent
          key={transaction.transactionHash}
          transaction={transaction}
        />
      ))}
    </Flex>
  );
};
