'use client';

import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { BodySmall, Flex } from './base';
import { cn } from '../utils';
import { useState } from 'react';
import IconButton from './base/IconButton';
import { ArrowLeftIcon, ArrowRightIcon } from '@radix-ui/react-icons';
import { useIsMobile } from 'hooks';

interface GridItemProps {
  functionName?: string;
  selectorIndex: number;
  className?: string;
}

const GridItem = ({
  className,
  functionName,
  selectorIndex,
}: GridItemProps) => {
  const { selector, setSelector } = useFunctionSelect();
  return (
    <button
      type='button'
      onClick={() => setSelector(selectorIndex)}
      className={cn(
        selector === selectorIndex
          ? 'text-platinum bg-arsenic rounded-full'
          : ' text-dark-gray',
        'px-4 py-3 w-fit min-w-[140px]',
        className
      )}
    >
      <BodySmall>{functionName}</BodySmall>
    </button>
  );
};

export const FunctionNav = () => {
  const { isMobile } = useIsMobile();
  const [index, setIndex] = useState<number>(0);
  const { selector, setSelector } = useFunctionSelect();

  const functionNameMap = {
    0: 'setup',
    1: 'storeTokenData',
    2: 'overwriteTokenData',
    3: 'updatePressData',
  };

  const increment = () => {
    if (index < 3) {
      setIndex(index + 1);
      setSelector(index + 1);
    }
  };

  const decrement = () => {
    if (index >= 1) {
      setIndex(index - 1);
      setSelector(index - 1);
    }
  };

  if (isMobile) {
    return (
      <Flex className='items-center gap-x-3'>
        <IconButton
          className={cn(index === 0 ? 'text-arsenic' : ' text-dark-gray')}
          icon={<ArrowLeftIcon />}
          callback={decrement}
        />
        <GridItem
          className='rounded-full bg-eerie-black w-fit min-w-[140px] text-platinum'
          functionName={functionNameMap[index]}
          selectorIndex={index}
        />
        <IconButton
          className={cn(index === 3 ? 'text-arsenic' : ' text-dark-gray')}
          icon={<ArrowRightIcon />}
          callback={increment}
        />
      </Flex>
    );
  }

  return (
    <Flex className='justify-between gap-x-2 rounded-full bg-eerie-black w-fit'>
      <GridItem functionName={'setup'} selectorIndex={0} />
      <GridItem functionName={'storeTokenData'} selectorIndex={1} />
      <GridItem functionName={'overwriteTokenData'} selectorIndex={2} />
      <GridItem functionName={'updatePressData'} selectorIndex={3} />
    </Flex>
  );
  // }
};
