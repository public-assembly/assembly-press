'use client';

import {
  recentRawTransactions,
  type RawTransaction,
} from 'gql/requests/recentRawTransactions';
import { useEffect, useState } from 'react';
import { Caption, Flex, Grid, Debug, BodySmall, CaptionLarge } from '../base';
import { cn } from '@/utils/cn';

type RawTransactionFieldProps = {
  rawTransactions:
    | RawTransaction['createdAt']
    | RawTransaction['eventType']
    | RawTransaction['transactionHash'];
  className?: string;
};

type RawTransactionHashProps = RawTransactionFieldProps;

type EventTypeProps = {
  rawTransactions: RawTransaction['eventType'];
  className?: string;
};

type RawTransactionComponentProps = {
  rawTransactions: RawTransaction;
  className?: string;
};

type RawTransactionsTableProps = {
  className?: string;
};

const EventType = ({ rawTransactions, className }: EventTypeProps) => (
  <Flex
    className={cn(
      rawTransactions === 'DataStored' ||
      rawTransactions === 'DataRemoved' ||
      rawTransactions === 'DataOverwritten'
        ? 'border-heliotrope'
        : rawTransactions === 'LogicUpdated' || rawTransactions === 'RendererUpdated'
        ? 'border-malachite'
        : 'border-picton-blue',
      'border rounded-[2px] px-2 py-[2px] justify-center items-center w-[150px]'
    )}
  >
    <Caption className='text-platinum'>
      <p>{rawTransactions.toString()}</p>
    </Caption>
  </Flex>
);

const RawTransactionField = ({
  rawTransactions,
  className,
}: RawTransactionFieldProps) => (
  <CaptionLarge className='text-platinum'>
    <p>{rawTransactions.toString()}</p>
  </CaptionLarge>
);

const TransactionHash = ({ rawTransactions, className }: RawTransactionHashProps) => (
  <Flex className='px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
    <BodySmall className='text-dark-gray'>{rawTransactions.toString()}</BodySmall>
  </Flex>
);

const RawTransactionComponent = ({
  rawTransactions,
  className,
}: RawTransactionComponentProps) => (
  <Grid className='grid-cols-3 items-center my-2'>
    <EventType rawTransactions={rawTransactions.eventType} />
    <Flex className='justify-center'>
      <RawTransactionField rawTransactions={rawTransactions.createdAt} />
    </Flex>
    <Flex className='justify-end'>
      <TransactionHash
        rawTransactions={rawTransactions.transactionHash.slice(0, 10)}
      />
    </Flex>
  </Grid>
);

const RawTransactionsTableSkeleton = ({ className }: RawTransactionsTableProps) => {
  return (
    <div className='col-start-1 col-end-2 row-start-2 row-end-3'>
      <div className='border border-arsenic w-full h-full rounded-xl animate-pulse'>
        {}
      </div>
    </div>
  );
};

export const RawTransactionsTable = ({ className }: RawTransactionsTableProps) => {
  const [rawTransactions, setRawTransactions] = useState<RawTransaction[]>();

  useEffect(() => {
    (async () => {
      try {
        const rawTransactions = await recentRawTransactions();
        setRawTransactions(rawTransactions);
      } catch (err) {
        console.log('Error... ', err);
      }
    })();
  }, [rawTransactions]);

  if (!rawTransactions) return <RawTransactionsTableSkeleton />;
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
      {rawTransactions.map((rawTransactions) => (
        <RawTransactionComponent
          key={rawTransactions.transactionHash}
          rawTransactions={rawTransactions}
        />
      ))}
    </Flex>
  );
};


