import { Grid, VStack, Stack, Flex, BodyLarge } from '@/components/base';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { FunctionNav } from '@/components/FunctionNav';
import { CodeViewer } from '@/components/codeViewer/CodeViewer';
import { TxnSubmitter } from '@/components/txnSubmitter/TxnSubmitter';
import { RawTransactionsTable } from '@/components/RawTransactionsTable';
import { ArweaveBox } from '@/components/arweave';

export default function Page() {
  /* Visit `styles/globals.css` for hardcoded section sizes */
  return (
    <>
      <Header />
      <main>
        <Flex className='w-full justify-center pb-16'>
          <FunctionNav />
        </Flex>
        <Grid className='grid-cols-1 md:grid-cols-5 gap-4'>
          {/* Row 1 */}

          {/* Protocol */}
          <div className='md:col-start-1 md:col-end-3'>
            <BodyLarge className='text-platinum mb-4 align-left'>
              Protocol
            </BodyLarge>
            <div className='bg-[#16171A] border border-arsenic rounded-xl'>
              <CodeViewer language={'solidity'} />
            </div>
          </div>

          {/* Frontend */}
          <div className='md:col-start-3 md:col-end-5'>
            <BodyLarge className='text-platinum mb-4 align-left'>
              Frontend
            </BodyLarge>
            <div className='bg-[#16171A] border border-arsenic rounded-xl '>
              <CodeViewer language={'typescript'} />
            </div>
          </div>

          {/* Transaction Submitter */}
          <div>
            <BodyLarge className='text-platinum mb-4 align-left'>
              Transaction Submitter
            </BodyLarge>
            <div className='bg-[#16171A] text-white border border-arsenic rounded-xl'>
              <TxnSubmitter />
            </div>
          </div>
          {/* Row 2 */}

          {/* Database */}
          <div className='md:col-start-1 md:col-end-4'>
            <BodyLarge className='text-platinum mb-4 align-left'>
              Database
            </BodyLarge>
            <RawTransactionsTable />
          </div>

          {/* Arweave Backups */}
          <div className='md:col-start-4 md:col-end-6'>
            <BodyLarge className='text-platinum mb-4 align-left'>
              Arweave Backups
            </BodyLarge>
            <ArweaveBox className='border border-arsenic w-full rounded-xl' />
          </div>
        </Grid>
      </main>
      <Footer />
    </>
  );
}
