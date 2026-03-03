'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignUp, setIsSignUp] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ text: string; isError: boolean } | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setMessage(null);

    const supabase = createClient();

    try {
      if (isSignUp) {
        const { error } = await supabase.auth.signUp({ email, password });
        if (error) throw error;
        setMessage({ text: 'Check your email to confirm your account.', isError: false });
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) throw error;
        router.push('/');
        router.refresh(); // re-renders server components with the new session
      }
    } catch (e: unknown) {
      setMessage({ text: e instanceof Error ? e.message : String(e), isError: true });
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="min-h-screen bg-bg flex items-center justify-center px-5">
      <div className="w-full max-w-sm">
        <h1 className="text-white text-3xl font-extrabold text-center mb-2">FitRPG</h1>
        <p className="text-muted text-sm text-center mb-8">
          {isSignUp ? 'Create your account' : 'Sign in to your account'}
        </p>

        <form onSubmit={handleSubmit} className="flex flex-col gap-3">
          <input
            type="email"
            placeholder="Email"
            value={email}
            onChange={e => setEmail(e.target.value)}
            required
            className="bg-card border border-border rounded-xl px-4 py-3 text-white
                       placeholder:text-muted focus:outline-none focus:border-accent text-sm"
          />
          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
            className="bg-card border border-border rounded-xl px-4 py-3 text-white
                       placeholder:text-muted focus:outline-none focus:border-accent text-sm"
          />

          {message && (
            <p className={`text-sm ${message.isError ? 'text-red-400' : 'text-accent'}`}>
              {message.text}
            </p>
          )}

          <button
            type="submit"
            disabled={loading}
            className="bg-accent hover:bg-green-600 disabled:opacity-50 text-white
                       font-bold py-3 rounded-xl transition-colors mt-1 cursor-pointer"
          >
            {loading ? 'Loading…' : isSignUp ? 'Sign Up' : 'Sign In'}
          </button>
        </form>

        <button
          onClick={() => { setIsSignUp(v => !v); setMessage(null); }}
          className="text-accent text-sm text-center w-full mt-5 hover:underline cursor-pointer"
        >
          {isSignUp ? 'Already have an account? Sign in' : "Don't have an account? Sign up"}
        </button>
      </div>
    </main>
  );
}
