'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { BodySmall, Flex } from './base';
import { cn } from '../utils';

interface GridItemProps {
  functionName: string;
  selectorIndex: number;
}

const GridItem = ({ functionName, selectorIndex }: GridItemProps) => {
  const { selector, setSelector } = useFunctionSelect();
  return (
    <button
      type='button'
      onClick={() => setSelector(selectorIndex)}
      className={cn(
        selector === selectorIndex
          ? 'text-platinum bg-arsenic rounded-full'
          : ' text-dark-gray',
        'px-4 py-3 w-28'
      )}
    >
      <BodySmall>{functionName}</BodySmall>
    </button>
  );
};

export const FunctionNav = () => {
  return (
    <Flex className='justify-between gap-x-2 rounded-full bg-eerie-black w-fit'>
      <GridItem functionName={'setupAP721'} selectorIndex={0} />
      <GridItem functionName={'setLogic'} selectorIndex={1} />
      <GridItem functionName={'setRenderer'} selectorIndex={2} />
      <GridItem functionName={'store'} selectorIndex={3} />
      <GridItem functionName={'overwrite'} selectorIndex={4} />
    </Flex>
  );
};
