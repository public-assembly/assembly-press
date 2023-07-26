import * as React from 'react'
import useSWR from 'swr'

/**
 * Supply an Ethereum address to see how many Public Assembly tokens it holds.
 */

export function useOwnedTokens(ownerAddress: `0x${string}`) {
  const { data: balanceOf, error: balanceOfError } = useSWR(
    `https://ether.actor/0xd2E7684Cf3E2511cc3B4538bB2885Dc206583076/balanceOf/${ownerAddress}`,
  )

  return {
    balanceOf,
    balanceOfError,
  }
}
