import { VStack } from '@/components/base/Stack';
import { Header } from '../components/Header';
import { Footer } from '../components/Footer';
import { TransactionsTable } from '@/components/server';

export default function Page() {
  return (
    <VStack className='min-h-screen px-8'>
      <Header />
      <section
        style={{
          minHeight: 'calc(100vh - 400px)',
        }}
        className='mt-32'
      >
        {/* <ButtonGrid /> */}
        <TransactionsTable />
      </section>
      <Footer />
    </VStack>
  );
}
