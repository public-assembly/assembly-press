'use client'

import NextNProgress from 'nextjs-progressbar'
import { ConnectKitProvider } from 'connectkit'
import * as React from 'react'
import { WagmiConfig } from 'wagmi'
import { config } from '../wagmiConfig'

export function Providers({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = React.useState(false)
  React.useEffect(() => setMounted(true), [])
  return (
    <WagmiConfig config={config}>
      <ConnectKitProvider theme="midnight">
        <NextNProgress
          color="#cdf15e"
          startPosition={0.125}
          stopDelayMs={200}
          height={2}
          showOnShallow={true}
          options={{ showSpinner: false }}
        />
        {mounted && children}
      </ConnectKitProvider>
    </WagmiConfig>
  )
}
