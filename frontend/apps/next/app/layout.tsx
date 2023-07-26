import '../styles/globals.css'
import { Providers } from './providers'
import { Metadata } from 'next'
import { IBM_Plex_Mono } from 'next/font/google'

const ibm_plex_mono = IBM_Plex_Mono({
  subsets: ['latin'],
  display: 'swap',
  weight: ['500'],
  variable: '--font-ibm-plex-mono',
})

export const metadata: Metadata = {
  title: 'Public Assembly - Assemble Package',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={ibm_plex_mono.className}>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  )
}
