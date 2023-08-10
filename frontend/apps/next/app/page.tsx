import { Grid, VStack, Stack, Flex } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';

import { CodeViewer } from '@/components/codeViewer/CodeViewer';
import { FunctioNav } from '@/components/FunctionNav';
import { RawTransactionsTable } from '@/components/server';
import { ArweaveBox } from '@/components/arweave';

export default function Page() {
  // Visit `styles/globals.css` for hardcoded section sizes

  return (
    <VStack className='min-h-screen px-4 sm:px-8'>
      <Header />
      <main>
        <Flex className='w-full justify-center mb-6'>
          <FunctioNav />
        </Flex>
        <Grid className='grid-rows-2 grid-cols-4 gap-4'>
          {/* row 1 */}
            <div className='row-start-1 row-end-2 col-start-1 col-end-4 flex gap-4'>
              {/* {"row 1 col 1 pt 1"} */}
              <div className='border border-arsenic w-6/12 h-full rounded-xl'>
                <CodeViewer language={'typescript'} />
              </div>
              {/* {"row 1 col 1 pt 2"} */}
              <div className='border border-arsenic w-6/12 h-full rounded-xl'>
                <CodeViewer language={'solidity'} />
              </div>              
            </div>          
            {/* {row 1 col 2} */}
            <div className='col-start-4 col-end-5 row-start-1 row-end-2'>
              <div className='border border-arsenic w-full h-full rounded-xl'>
              {"row 1 col 2"}
              </div>
            </div>            
          {/* row 2 */}
          {/* {row 2 col 1} */}
          <RawTransactionsTable className='' />
          {/* {row 2 col 2} */}
          <ArweaveBox className='row-start-2 row-end-3 col-start-4 col-end-5  border border-arsenic w-full h-full rounded-xl' />
        </Grid>
      </main>
      <Footer />
    </VStack>
  );
}
