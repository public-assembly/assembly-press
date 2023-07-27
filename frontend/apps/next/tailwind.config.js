/** @type {import('tailwindcss').Config} */

module.exports = {
  content: [
    './app/**/*.{js,ts,jsx,tsx, md, mdx}',
    './components/**/*.{js,ts,jsx,tsx, md, mdx}',
    './../../packages/**/*.{js,ts,jsx,tsx, md, mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'eerie-black': '#1C1D20',
        'maximum-green-yellow': '#CDF15E',
      },
      fontFamily: {
        sans: ['var(--font-ibm-plex-mono)'],
      },
    },
  },
}
