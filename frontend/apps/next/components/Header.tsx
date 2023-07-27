import { Navigation } from './Navigation'
import { ConnectKitButton } from 'connectkit'

export function Header() {
  return (
    <header className="bg-eerie-black flex w-full flex-row items-center justify-between px-8 lg:sticky lg:top-0 lg:shadow-2xl">
      <Navigation />
      <ConnectKitButton />
    </header>
  )
}
