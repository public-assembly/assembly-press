import React, { FC, MouseEventHandler } from 'react';
import { SvgLoader } from './SvgLoader';

interface ButtonProps {
  text: string;
  callback: MouseEventHandler;
  callbackLoading: boolean;
}

export const Button: FC<ButtonProps> = ({
  text,
  callback,
  callbackLoading,
}) => {
  return (
    <button
      type='button'
      className='bg-arsenic rounded-md w-full py-4 px-4 hover:bg-black-coral text-platinum'
      onClick={!callbackLoading ? callback : undefined}
      disabled={callbackLoading}
    >
      {callbackLoading ? <SvgLoader /> : text}
    </button>
  );
};
