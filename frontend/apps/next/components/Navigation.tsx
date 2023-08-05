import Link from 'next/link';
import { BodySmall } from './base';

const pages = [
  {
    slug: '/',
    title: 'Assembly Press',
  },
];

export function Navigation() {
  return (
    <div className='flex gap-x-4 items-center'>
      {pages.map((page) => (
        <Link passHref href={page.slug} key={page.slug}>
          <BodySmall className='text-dark-gray'>{page.title}</BodySmall>
        </Link>
      ))}
      <span className='text-arsenic'>|</span>
      <BodySmall className='text-dark-gray'>Demo</BodySmall>
    </div>
  );
}
