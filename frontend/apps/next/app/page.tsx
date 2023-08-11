import { Grid, VStack, Stack, Flex } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { CodeViewer } from '@/components/codeViewer/CodeViewer';
import { FunctioNav } from '@/components/FunctionNav';
import { RawTransactionsTable } from '@/components/server';
import { ArweaveBox } from '@/components/arweave';

export default function Page() {
  {/* Visit `styles/globals.css` for hardcoded section sizes */}

  return (
    <VStack className='px-4 sm:px-8'>
      <Header />
      <main>
        <Flex className='w-full justify-center mb-6'>
          <FunctioNav />
        </Flex>
        <Grid className='grid-rows-2 grid-cols-8 gap-4'>
          {/* Row 1 */}
          <div className='row-start-1 row-end-2 col-start-1 col-end-7 flex gap-4'>
            <div className='bg-[#16171A] border border-arsenic w-6/12 h-full rounded-xl'>
              <CodeViewer language={'typescript'} />
            </div>
            <div className='bg-[#16171A]  border border-arsenic w-6/12 h-full rounded-xl'>
              <CodeViewer language={'solidity'} />
            </div>              
          </div>          
          <div className='col-start-7 col-end-9 row-start-1 row-end-2'>
            <div className='bg-[#16171A] text-white border border-arsenic w-full h-full rounded-xl'>
            {"row 1 col 2"}
            </div>
          </div>            
          {/* Row 2 */}
          <RawTransactionsTable className='' />
          <ArweaveBox className='border border-arsenic w-full h-full rounded-xl' />
        </Grid>
      </main>
      <Footer />
    </VStack>    
  )
}
