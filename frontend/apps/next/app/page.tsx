'use client'

import { Header, Footer } from '../components'
import { ButtonGrid } from '../components'
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
