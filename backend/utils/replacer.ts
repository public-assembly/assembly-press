// rome-ignore lint: allow explicit any
export const replacer = (key: string, value: any) => {
  if (typeof value === 'bigint') {
    return value.toString()
  }
  return value
}
