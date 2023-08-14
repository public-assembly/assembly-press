import { Grid, VStack, Stack, Flex } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { FunctioNav } from '@/components/FunctionNav';
import { CodeViewer } from '@/components/codeViewer/CodeViewer';
import { TxnSubmitter } from '@/components/txnSubmitter/TxnSubmitter';
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
        <div className='flex flex-col lg:flex-row gap-4'>
          <div className='flex flex-col lg:flex-row gap-4 mb-4 w-full'>
            {/* Code Viewers */}
            <div className='bg-[#16171A] border border-arsenic w-full lg:w-1/2 rounded-xl mb-4 lg:mb-0'>
              <CodeViewer language={'typescript'} />
            </div>
            <div className='bg-[#16171A] border border-arsenic w-full lg:w-1/2 rounded-xl'>
              <CodeViewer language={'solidity'} />
            </div>              
          </div>

          {/* Transaction Submitter */}
          <div className='bg-[#16171A] text-white border border-arsenic w-full lg:w-1/4 rounded-xl mb-4'>
            <TxnSubmitter />
          </div>
        </div>

        <div className='flex flex-col lg:flex-row gap-4'>
          {/* Raw Transactions Table */}
          <div className='w-full lg:w-3/4'>
            <RawTransactionsTable />
          </div>

          {/* Arweave Box */}
          <div className='w-1/2 h-1/2 p-2' >
          <ArweaveBox className='max-w-screen-sm rounded-xl'/>
          </div>
        </div>
      </main>
      <Footer />
    </VStack>    
  )
}
