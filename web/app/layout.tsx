// TODO Phase 2: wrap with Supabase auth provider + session check
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'FitRPG Dashboard',
  description: 'Your fitness and gaming progress hub',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="bg-bg">
      <body className="bg-bg text-white antialiased">
        {children}
      </body>
    </html>
  );
}
