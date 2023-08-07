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
        'dark-gray': '#A7A8A9',
        arsenic: '#3F4144',
        platinum: '#E4E4E4',
        malachite: '#04CD49',
        heliotrope: '#D458FB',
        'raisin-black': '#1F2124',
        'dark-gunmental': '#232528',
        'picton-blue': '#4BA5F5',
      },
      fontFamily: {
        sans: ['var(--font-satoshi)'],
        mono: ['var(--font-space-mono)'],
      },
    },
  },
};
