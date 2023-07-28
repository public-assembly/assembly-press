import { Navigation } from './Navigation';
import { ConnectKitButton } from 'connectkit';

export function Header() {
  return (
    <header className='flex w-full items-center justify-between px-8 lg:sticky'>
      <Navigation />
      <ConnectKitButton />
    </header>
  );
}
