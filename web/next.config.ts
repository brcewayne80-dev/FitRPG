import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  output: 'standalone', // Produces .next/standalone/server.js for Pi deployment
};

export default nextConfig;
