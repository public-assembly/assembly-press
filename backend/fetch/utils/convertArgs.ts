import { DatabaseLog } from '../../types'

export function convertArgs(args: object): DatabaseLog['args'] | undefined {
  const convertedArgs: Partial<DatabaseLog['args']> = {}

  for (const key in args) {
    if (Object.prototype.hasOwnProperty.call(args, key)) {
      // rome-ignore lint: allow explicit any
      ;(convertedArgs as Record<string, any>)[key] =
        // rome-ignore lint: allow explicit any
        (args as Record<string, any>)[key]
    }
  }

  return convertedArgs as DatabaseLog['args'] // Cast to DatabaseLog['args'] to assert the final type
}
