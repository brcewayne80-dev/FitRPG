import { createClient, type SupabaseClient } from '@supabase/supabase-js';

let _client: SupabaseClient | null = null;

/**
 * Returns a Supabase client authenticated with the token passed in the URL
 * query parameter `?token=<access_token>`. The dashboard's Play button injects
 * this token when opening the game in a new tab.
 *
 * Returns null if env vars are missing. All callers handle null gracefully
 * (fall back to allowing upgrades for free).
 */
export function getSupabaseClient(): SupabaseClient | null {
  if (_client) return _client;

  const url  = import.meta.env.VITE_SUPABASE_URL as string | undefined;
  const anon = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
  if (!url || !anon) return null;

  const token = new URLSearchParams(window.location.search).get('token');

  _client = createClient(url, anon, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: token
      ? { headers: { Authorization: `Bearer ${token}` } }
      : {},
  });

  // Set session so auth.uid() resolves correctly in RLS policies
  if (token) {
    _client.auth.setSession({ access_token: token, refresh_token: '' }).catch(() => {});
  }

  return _client;
}
