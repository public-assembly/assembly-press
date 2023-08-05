export const entries = {
  github: 'https://github.com/public-assembly/assembly-press',
  discourse: 'https://forum.public---assembly.com/',
  twitter: 'https://twitter.com/pblcasmbly',
}

export const links = Object.keys(entries).map((key) => {
  return {
    platform: key,
    url: entries[key as keyof typeof entries],
  }
})
