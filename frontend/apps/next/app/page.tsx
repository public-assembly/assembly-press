'use client';

import { VStack } from '@/components/base';
import { Header, Footer, ButtonGrid } from '../components';

export default function Page() {
  return (
    <VStack className='min-h-screen px-8'>
      <Header />
      <section
        style={{
          minHeight: 'calc(100vh - 400px)',
        }}
        className='px-8 mt-24'
      >
        {/* <ButtonGrid /> */}
      </section>
      <Footer />
    </VStack>
  );
}
