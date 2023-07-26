export const entries = {
  twitter: 'https://twitter.com/pblcasmbly',
  forum: 'https://forum.public---assembly.com/',
  github: 'https://github.com/public-assembly/assemble-package',
  governance:
    'https://nouns.build/dao/0xd2e7684cf3e2511cc3b4538bb2885dc206583076',
}

export const links = Object.keys(entries).map((key) => {
  return {
    platform: key,
    url: entries[key as keyof typeof entries],
  }
})
