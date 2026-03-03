import { getSupabaseClient } from '../lib/supabase';

const SAVE_KEY = 'dtv_save';

export interface SaveData {
  highest_wave_reached: number;
  upgrades: {
    archer_power: number;
    archer_speed: number;
    tower_archers: number;
    tower_health: number;
    catapult_unlocked: number;
    catapult_power: number;
    catapult_speed: number;
    catapult_aoe: number;
    outpost_unlocked: number;
    outpost_strength: number;
    outpost_archers: number;
    outpost_power: number;
    outpost_speed: number;
  };
}

const DEFAULT: SaveData = {
  highest_wave_reached: 1,
  upgrades: {
    archer_power: 0,
    archer_speed: 0,
    tower_archers: 0,
    tower_health: 0,
    catapult_unlocked: 0,
    catapult_power: 0,
    catapult_speed: 0,
    catapult_aoe: 0,
    outpost_unlocked: 0,
    outpost_strength: 0,
    outpost_archers: 0,
    outpost_power: 0,
    outpost_speed: 0,
  },
};

export function loadSave(): SaveData {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return structuredClone(DEFAULT);
    const parsed = JSON.parse(raw) as Partial<SaveData>;
    const save = structuredClone(DEFAULT);
    if (typeof parsed.highest_wave_reached === 'number') {
      save.highest_wave_reached = parsed.highest_wave_reached;
    }
    if (parsed.upgrades && typeof parsed.upgrades === 'object') {
      for (const k of Object.keys(save.upgrades) as (keyof SaveData['upgrades'])[]) {
        const v = parsed.upgrades[k];
        if (typeof v === 'number') save.upgrades[k] = Math.max(0, Math.floor(v));
      }
    }
    return save;
  } catch {
    return structuredClone(DEFAULT);
  }
}

export function writeSave(save: SaveData): void {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(save));
  } catch {
    // storage quota exceeded — ignore
  }
  syncSaveToSupabase(save);
}

function syncSaveToSupabase(save: SaveData): void {
  const sb = getSupabaseClient();
  if (!sb) return;
  sb.auth.getUser().then(({ data }) => {
    if (!data.user) return;
    sb.from('game_saves').upsert(
      { user_id: data.user.id, game_key: 'dtv', save_data: save, updated_at: new Date().toISOString() },
      { onConflict: 'user_id,game_key' },
    ).then(() => {});
  });
}

export function setHighestWaveIfGreater(save: SaveData, wave: number): void {
  if (wave > save.highest_wave_reached) {
    save.highest_wave_reached = wave;
    writeSave(save);
  }
}

/** Write current runtime upgrade levels back to save (take max so you never lose progress). */
export function writeUpgrades(save: SaveData, updates: Partial<SaveData['upgrades']>): void {
  for (const k of Object.keys(updates) as (keyof SaveData['upgrades'])[]) {
    const v = updates[k];
    if (typeof v === 'number') {
      save.upgrades[k] = Math.max(save.upgrades[k], Math.max(0, v));
    }
  }
  writeSave(save);
}
