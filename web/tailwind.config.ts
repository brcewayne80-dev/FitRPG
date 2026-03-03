import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{ts,tsx}',
    './src/**/*.{ts,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        bg:     '#0f0f0f',
        card:   '#1e1e1e',
        accent: '#4CAF50',
        border: '#2a2a2a',
        muted:  '#888888',
        subtle: '#555555',
        dim:    '#666666',
      },
      fontFamily: {
        sans: ['system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'sans-serif'],
      },
    },
  },
  plugins: [],
};

export default config;
