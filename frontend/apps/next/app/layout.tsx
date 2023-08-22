import '../styles/globals.css';
import { Providers } from './providers';
import type { Metadata } from 'next'
import { Space_Mono } from 'next/font/google';
import localFont from 'next/font/local';

const space_mono = Space_Mono({
  variable: '--font-space-mono',
  style: ['normal'],
  weight: ['400', '700'],
  subsets: ['latin'],
})

const satoshi = localFont({
  variable: '--font-satoshi',
  src: [
    {
      path: '../fonts/Satoshi-Regular.woff2',
      weight: '400',
      style: 'regular',
    },
    {
      path: '../fonts/Satoshi-Italic.woff2',
      weight: '400',
      style: 'italic',
    },
    {
      path: '../fonts/Satoshi-Medium.woff2',
      weight: '500',
      style: 'medium',
    },
    {
      path: '../fonts/Satoshi-MediumItalic.woff2',
      weight: '500',
      style: 'italic',
    },
    {
      path: '../fonts/Satoshi-Bold.woff2',
      weight: '700',
      style: 'bold',
    },
    {
      path: '../fonts/Satoshi-BoldItalic.woff2',
      weight: '700',
      style: 'italic',
    },
  ],
});

export const metadata: Metadata = {
  title: 'Assembly Press | Demo',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang='en' className={`${satoshi.variable} ${space_mono.variable} bg-raisin-black`}>
      <body className='px-8'>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
