import clsx from 'clsx'
import { PropsWithChildren } from 'react'

type GridProps = PropsWithChildren<{
  className?: string
}>

export function Grid({ className, children }: GridProps) {
  return <div className={clsx('grid ', className)}>{children}</div>
}

Grid.displayName = 'Grid'
