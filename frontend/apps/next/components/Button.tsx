import React, { FC, MouseEventHandler } from 'react'
import { SvgLoader } from './SvgLoader'

interface ButtonProps {
  text: string
  callback: MouseEventHandler
  callbackLoading: boolean
}

export const Button: FC<ButtonProps> = ({
  text,
  callback,
  callbackLoading,
}) => {
  return (
    <button
      className="border-[1px] border-white w-[150px] py-4 px-4 rounded hover:bg-[#cdf15e] hover:text-[#1c1d20]"
      onClick={!callbackLoading ? callback : undefined}
      disabled={callbackLoading}
    >
      {callbackLoading ? <SvgLoader /> : text}
    </button>
  )
}
