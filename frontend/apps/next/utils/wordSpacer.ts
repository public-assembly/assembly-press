export function camelToSpaced(s: string) {
    let count = 0;
    return s
      .replace(/([A-Z])/g, (match) => {
        count++;
        return count === 2 ? ` ${match}` : match;
      })
      .trim();
  }