import * as React from 'react'
import { type Hex } from 'viem'
import { useOwnedTokens } from '../hooks'

type WebThreeComponentProps = {
  text?: string
  address: Hex
}

export function WebThreeComponent(props: WebThreeComponentProps) {
  const { balanceOf, balanceOfError } = useOwnedTokens(props.address)

  return (
    <div className="flex w-screen justify-center gap-1 rounded-xl border border-solid border-gray-200 p-4">
      {props.text && <span>{props.text}</span>}
      <pre className="py-[10px] overflow-x-scroll">
        {balanceOf ? (
          <code>
            Public Assembly Token Balance:{' '}
            {JSON.stringify({ balanceOf }, null, 2)}
          </code>
        ) : (
          <code>{JSON.stringify({ balanceOfError }, null, 2)}</code>
        )}
      </pre>
    </div>
  )
}
