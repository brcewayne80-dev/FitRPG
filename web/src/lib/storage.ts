import { createClient } from './supabase/client';

export interface XPEvent {
  delta: number;
  source: string;
  ts: string;
}

export interface DTVSave {
  highest_wave_reached: number;
  upgrades: Record<string, number>;
}

/** Returns the user's total lifetime XP from Supabase. */
export async function getTotalXP(): Promise<number> {
  const { data } = await createClient().from('xp_events').select('delta');
  return (data ?? []).reduce((sum, r) => sum + (r.delta as number), 0);
}

/** Returns the user's XP earned today (midnight local time onwards). */
export async function getTodayXP(): Promise<number> {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const { data } = await createClient()
    .from('xp_events')
    .select('delta')
    .gte('ts', start.toISOString());
  return (data ?? []).reduce((sum, r) => sum + (r.delta as number), 0);
}

/** Returns the Defend the Valley save from Supabase, or null if none exists. */
export async function getDTVSave(): Promise<DTVSave | null> {
  const { data } = await createClient()
    .from('game_saves')
    .select('save_data')
    .eq('game_key', 'dtv')
    .single();
  if (!data) return null;
  const s = data.save_data as Partial<DTVSave>;
  if (typeof s.highest_wave_reached !== 'number') return null;
  return {
    highest_wave_reached: s.highest_wave_reached,
    upgrades: s.upgrades && typeof s.upgrades === 'object'
      ? (s.upgrades as Record<string, number>)
      : {},
  };
}
