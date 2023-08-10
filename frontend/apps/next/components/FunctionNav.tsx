'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { Grid, BodySmall, Flex } from './base';
import { cn } from '../utils';

interface GridItemProps {
  functionName: string;
  selectorIndex: number;
}

const GridItem = ({ functionName, selectorIndex }: GridItemProps) => {
  const { selector, setSelector } = useFunctionSelect();
  return (
    <button type='button' onClick={() => setSelector(selectorIndex)}>
      <BodySmall
        className={cn(
          selector === selectorIndex ? 'text-platinum' : ' text-dark-gray',
          ''
        )}
      >
        {functionName}
      </BodySmall>
    </button>
  );
};

export const FunctioNav = () => {
  return (
    <Flex className='justify-between gap-x-6 '>
      <GridItem functionName={'setupAP721'} selectorIndex={0} />
      <GridItem functionName={'setLogic'} selectorIndex={1} />
      <GridItem functionName={'setRenderer'} selectorIndex={2} />
      <GridItem functionName={'store'} selectorIndex={3} />
      <GridItem functionName={'overwrite'} selectorIndex={4} />
    </Flex>
  );
};
