'use client';

import { ConnectKitProvider } from 'connectkit';
import { FunctionSelectProvider } from 'context/FunctionSelectProvider';
import * as React from 'react';
import { WagmiConfig } from 'wagmi';
import { config } from '../wagmiConfig';

export function Providers({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = React.useState(false);
  React.useEffect(() => setMounted(true), []);
  return (
    <WagmiConfig config={config}>
      <ConnectKitProvider
        customTheme={{
          '--ck-font-family': 'var(--font-satoshi)',
          '--ck-border-radius': 12,
        }}
      >
        <FunctionSelectProvider>
          {mounted && children}
        </FunctionSelectProvider>
      </ConnectKitProvider>
    </WagmiConfig>
  );
}
