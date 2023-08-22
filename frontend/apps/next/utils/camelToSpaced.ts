export function camelToSpaced(s: string) {
  return s
    .replace(/([A-Z])/g, (match, index) => (index === 0 ? match : ` ${match}`))
    .trim();
}
