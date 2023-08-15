import { useEffect, useState } from 'react'

const MOBILE_WIDTH = 769

export function isAndroid(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    /Android\s([0-9.]+)/.test(navigator.userAgent) // Source: https://github.com/DamonOehlman/detect-browser/blob/master/src/index.ts
  )
}

export function isIOS(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    /Version\/([0-9._]+).*Mobile.*Safari.*/.test(navigator.userAgent) // Source: https://github.com/DamonOehlman/detect-browser/blob/master/src/index.ts
  )
}

export function isMobile(): boolean {
  return isAndroid() || isIOS()
}

export const useIsMobile = () => {
  const [isMobileWidth, setIsMobileWidth] = useState<boolean | null>(null)
  const [, setWidth] = useState<number>(0)

  useEffect(() => {
    if (typeof window === 'undefined') return
    const getWidth = () => {
      setWidth(window.innerWidth)

      if (window.innerWidth <= MOBILE_WIDTH) {
        setIsMobileWidth(true)
      } else {
        setIsMobileWidth(false)
      }
    }

    window.addEventListener('resize', getWidth)

    getWidth()

    return () => {
      window.removeEventListener('resize', getWidth)
    }
  }, [])

  return {
    isMobile: isMobileWidth || isMobile(),
  }
}