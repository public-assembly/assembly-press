'use client';

import { links } from 'utils/links';
import { BodySmall } from '@/base/Typography';

export function Footer() {
  return (
    <footer className='flex flex-wrap items-center justify-center md:justify-between py-8 gap-2'>
      {/* Built by Public Assembly */}
      <BodySmall className='text-dark-gray'>Built by Public Assembly</BodySmall>
      {/* Right corner links */}
      <div className='flex gap-x-6'>
        {links.map((link) => (
          <BodySmall className='text-dark-gray capitalize hover:text-arsenic'>
            <a href={link.url} target='_blank' rel='noreferrer' key={link.url}>
              {link.platform}
            </a>
          </BodySmall>
        ))}
      </div>
    </footer>
  );
}
