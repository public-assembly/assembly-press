import Link from 'next/link'
import { usePathname } from 'next/navigation'

const pages = [
  {
    slug: '/',
    title: 'Assembly Press Demo',
  },
]

export function Navigation() {
  const pathname = usePathname()

  return (
    <div className="flex gap-x-8">
      {pages.map((page) => (
        <Link passHref href={page.slug} key={page.slug}>
          <p
            className={`font-sans text-xl text-white ${
              pathname === page.slug ? 'text-maximum-green-yellow ' : null
            }`}
          >
            {page.title}
          </p>
        </Link>
      ))}
    </div>
  )
}
