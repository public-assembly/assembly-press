import { Navigation } from './Navigation';
import { Connect } from './Connect';

export function Header() {
  return (
    <header className='flex w-full items-center justify-between'>
      <Navigation />
      <Connect />
    </header>
  );
}
