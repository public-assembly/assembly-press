import Link from 'next/link';
import { usePathname } from 'next/navigation';

const pages = [
  {
    slug: '/',
    title: 'Assembly Press',
  },
];

export function Navigation() {
  const pathname = usePathname();

  return (
    <div className='flex gap-x-4 items-center'>
      {pages.map((page) => (
        <Link passHref href={page.slug} key={page.slug}>
          <p
            className={`font-sans text-lg text-white ${
              pathname === page.slug ? 'text-maximum-green-yellow ' : null
            }`}
          >
            {page.title}
          </p>
        </Link>
      ))}
      <span className='text-[#313235]'>|</span>
      <div className='font-sans text-lg'>Demo</div>
    </div>
  );
}
