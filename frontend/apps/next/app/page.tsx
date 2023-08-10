import { Grid, VStack, Stack } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { ButtonGrid } from '../components/ButtonGrid';
import { RawTransactionsTable } from '@/components/server';
import { ArweaveBox } from '@/components/arweave';

export default function Page() {
  return (
    <VStack className='min-h-screen px-4 sm:px-8'>
      <Header />
      <main>
        <Grid className='grid-cols-1 sm:grid-cols-2 gap-4'>
          <ButtonGrid className='col-span-1 sm:col-start-1 sm:col-end-2' />
          
          {/* Code Snippets */}
          <div className='col-span-1 sm:col-start-2 sm:col-end-3'>
            <div className='border border-arsenic w-full h-full rounded-xl'>
              {}
            </div>
          </div>
          
          <RawTransactionsTable className='col-span-1 sm:col-start-1 sm:col-end-2' />

          <ArweaveBox className='col-span-1 border border-arsenic w-full h-full rounded-xl overflow-hidden' />


        </Grid>
      </main>
      <Footer />
    </VStack>
  );
}
