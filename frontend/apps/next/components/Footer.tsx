import { links } from 'utils/links';

export function Footer() {
  return (
    <footer className='flex w-full items-center justify-between border-t-[1px] border-white p-8 absolute bottom-0'>
      {links.map((link) => (
        <a
          className='font-sans text-6xl text-white hover:text-maximum-green-yellow'
          href={link.url}
          target='_blank'
          rel='noreferrer'
          key={link.url}
        >
          <span>{link.platform}</span>
        </a>
      ))}
    </footer>
  );
}
