'use client';

import { Header, Footer, ButtonGrid } from '../components';

export default function Page() {
  return (
    <>
      <Header />
      <section className='px-8 mt-24'>
        <ButtonGrid />
      </section>
      <Footer />
    </>
  );
}
