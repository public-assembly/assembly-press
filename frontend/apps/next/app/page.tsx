'use client'

import { Header, Footer, ButtonGrid } from '../components'
import Docs from './docs/docs.mdx'

export default function Page() {
  return (
    <>
      <Header />
      <section className='p-6'>
        <ButtonGrid />
      </section>
      <Footer />
    </>
  )
}
