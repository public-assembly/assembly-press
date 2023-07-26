'use client'

import { Header, Footer } from '../components'
import Docs from './docs/docs.mdx'

export default function Page() {
  return (
    <>
      <Header />
      <article>
        <Docs />
      </article>
      <Footer />
    </>
  )
}
