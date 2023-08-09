import React from 'react';
import Loading from '@/icons/Loading';
import { BodyLarge, Flex, BodySmall, VStack } from './base';
import IconButton, { type IconButtonProps } from './base/IconButton';

interface DescriptiveButtonProps extends IconButtonProps {
  label: string;
  description: string;
}

export const DescriptiveButton = ({
  label,
  description,
  callback,
  callbackLoading,
  icon,
}: DescriptiveButtonProps) => {
  return (
    <Flex className='border-[1px] border-arsenic py-4 px-4 rounded-xl gap-8 items-center h-fit w-fit'>
      <VStack>
        <BodyLarge className='text-platinum'>{label}</BodyLarge>
        <BodySmall className='text-dark-gray'>{description}</BodySmall>
      </VStack>
      <IconButton
        className='border-[1px] hover:bg-gray-600 border-arsenic rounded-[4px]'
        callback={callback}
        disabled={callbackLoading}
        icon={
          callbackLoading ? (
            <Loading className='animate-spin w-[15px] h-[15px]' />
          ) : (
            icon
          )
        }
      />
    </Flex>
  );
};
