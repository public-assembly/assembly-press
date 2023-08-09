import { Grid, VStack, Stack } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { ButtonGrid } from '../components/ButtonGrid';
import { TransactionsTable } from '@/components/server';
import { FetchPlayground } from '@/components/server/FetchPlayground';

export default function Page() {
  // Visit `styles/globals.css` for hardcoded section sizes
  return (
    <VStack className='min-h-screen px-8'>
      <Header />
      <main>
        <Grid className='grid-cols-2 grid-rows-2 gap-4'>
          <ButtonGrid className='col-start-1 col-end-2 row-start-1 row-end-2' />
          {/* Code Snippets */}
          <div className='col-start-2 col-end-3 row-start-1 row-end-2'>
            <div className='border border-arsenic w-full h-full rounded-xl'>
              {}
            </div>
          </div>
          <TransactionsTable className='col-start-1 col-end-2 row-start-2 row-end-3' />
        </Grid>
        {/* <FetchPlayground /> */}
      </main>
      <Footer />
    </VStack>
  );
}
