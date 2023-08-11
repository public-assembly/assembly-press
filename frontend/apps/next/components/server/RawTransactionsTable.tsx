'use client';

import {
  recentRawTransactions,
  type RawTransaction,
} from 'gql/requests/recentRawTransactions';
import { useEffect, useState } from 'react';
import { Caption, Flex, Grid, Debug, BodySmall, CaptionLarge } from '../base';
import { cn } from '@/utils/cn';
import { camelToSpaced } from '@/utils/wordSpacer';

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
      'uppercase border rounded-[2px] px-2 py-[2px] justify-center items-center w-fit'
    )}
  >
    <Caption className='text-platinum'>
      <p>{camelToSpaced(rawTransactions.toString())}</p>
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
  <a href={`https://goerli-optimism.etherscan.io/tx/${rawTransactions}`}>  
    <Flex className='hover:border-dark-gray  px-2 py-[2px] bg-dark-gunmetal rounded-[18px] border border-arsenic justify-center items-center w-fit'>
      <BodySmall className='text-dark-gray'>{rawTransactions.toString().slice(0, 10)}</BodySmall>
    </Flex>
  </a>  
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
        rawTransactions={rawTransactions.transactionHash}
      />
    </Flex>
  </Grid>
);

const RawTransactionsTableSkeleton = ({ className }: RawTransactionsTableProps) => {
  return (
    <div className='col-start-1 col-end-5 row-start-2 row-end-3'>
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
    <Flex className='row-start-2 row-end-3 col-start-1 col-end-6 flex-col w-full content-between border border-arsenic rounded-xl px-6 py-3'>
      <CaptionLarge className='text-platinum mb-4 align-left'>Database</CaptionLarge> 
      {/* Table Column Labels */}
      <Grid className='grid-cols-3 items-center my-2'>
        <BodySmall className='text-platinum'>Event Name</BodySmall>
        <Flex className='justify-center'>
          <BodySmall className='text-platinum'>Block Number</BodySmall>
        </Flex>
        <Flex className='justify-end'>
          <BodySmall className='text-platinum'>Transaction Hash</BodySmall>
        </Flex>
      </Grid>
      {rawTransactions.map((rawTransactions) => (
        <RawTransactionComponent
          key={rawTransactions.transactionHash}
          rawTransactions={rawTransactions}
        />
      ))}
    </Flex>
  );
};


