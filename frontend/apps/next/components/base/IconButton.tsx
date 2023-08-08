import React from 'react';
import { cn } from '@/utils/cn';
import { Debug } from './Debug';

export type IconButtonProps = React.ComponentPropsWithoutRef<'button'> & {
  icon: React.ReactNode;
  callback: (event: React.MouseEvent<HTMLElement>) => void;
  callbackLoading?: boolean;
  className?: string;
};

const IconButton = (props: IconButtonProps) => {
  return (
    <div>
      <button
        type='button'
        className={cn('p-[6px]', props.className)}
        onClick={props.callback}
        disabled={props.callbackLoading}
      >
        {props.icon}
      </button>
    </div>
  );
};

export default IconButton;
