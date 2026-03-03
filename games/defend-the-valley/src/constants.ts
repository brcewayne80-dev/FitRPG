// ─── Canvas ───────────────────────────────────────────────────────────────────
export const CANVAS_W = 1280;
export const CANVAS_H = 720;
export const FLOOR_Y = 609;  // world 578 + camera offset 31
export const FLOOR_JITTER_PX = 10;

// ─── Wave mechanics ───────────────────────────────────────────────────────────
export const WAVE_COUNTDOWN_SEC = 10;          // auto-send countdown
export const ENEMIES_PER_WAVE_GROWTH = 1.12;
export const SPAWN_INTERVAL_MS = 750;          // scene override (0.75 s)
export const SPAWN_X_OFFSET = 50;             // scene override (was 300 in script)

// ─── Enemy scaling (exponential from wave 6+, using wave-5 steps) ─────────────
export const ENEMY_HP_GROWTH = 1.08;
export const ENEMY_SPEED_GROWTH = 1.01;
export const ENEMY_DAMAGE_GROWTH = 1.03;
export const ORC_HP_MULTIPLIER = 0.55;

// ─── Large enemies ─────────────────────────────────────────────────────────────
export const LARGE_ENEMY_START_WAVE = 25;
export const LARGE_ENEMY_SPAWN_CHANCE = 0.35;
export const LARGE_ENEMY_SCALE = 1.25;
export const LARGE_ENEMY_HP_MULT = 1.4;

// ─── Enemy base stats ─────────────────────────────────────────────────────────
export const ENEMY_BASE_SPEED = 40;
export const ENEMY_BASE_HP = 60;
export const ENEMY_BASE_DAMAGE = 8;
export const ENEMY_ATTACK_INTERVAL_SEC = 0.9;

// ─── Screen positions (Godot world + camera offset: +66 x, +31 y) ──────────────
//   Camera2D at world (574, 329) → screen(0,0) = world(-66,-31)
//   screen = world + (66, 31)
export const TOWER_CONTACT = { x: 237, y: 613 };
export const ARCHER_MUZZLES = [
  { x: 178, y: 531 },  // Archer1Muzzle (lowest)
  { x: 174, y: 438 },  // Archer2Muzzle (middle)
  { x: 177, y: 392 },  // Archer3Muzzle (highest)
];

export const OUTPOST_POS     = { x: 490, y: 491 };
export const OUTPOST_CONTACT = { x: 528, y: 613 };
export const OUTPOST_MUZZLES = [
  { x: 512, y: 595 },
  { x: 510, y: 515 },
  { x: 506, y: 460 },
];

export const CATAPULT_POS    = { x: 283, y: 565 };
export const CATAPULT_MUZZLE = { x: 294, y: 514 };

// ─── Tower / Outpost HP ────────────────────────────────────────────────────────
export const TOWER_HP_BASE   = 250;
export const OUTPOST_HP_BASE = 140;

// ─── Archer shooting ──────────────────────────────────────────────────────────
export const ARCHER_DAMAGE_BASE    = 8;
export const ARCHER_FIRE_RATE_BASE = 0.7;   // shots/second
export const ARROW_X_NUDGE        = 8;
export const ARCHER_JITTER_DEG    = 9;      // max random angle spread

// ─── Projectile physics ───────────────────────────────────────────────────────
export const PROJECTILE_GRAVITY  = 1200;   // px/s²
export const SPEED_HINT          = 700;    // px/s (tune shot time)
export const MIN_SHOT_TIME       = 0.35;   // s
export const MAX_SHOT_TIME       = 0.95;   // s
export const ARROW_STICK_LIFE    = 1.0;    // s (arrow sticks in floor)
export const ARROW_MAX_LIFE      = 3.0;    // s safety cleanup

// ─── Catapult ─────────────────────────────────────────────────────────────────
export const CATAPULT_DAMAGE_BASE     = 30;
export const CATAPULT_FIRE_RATE_BASE  = 0.28;  // shots/second
export const CATAPULT_AOE_BASE        = 110;   // px radius
export const CATAPULT_GRAVITY         = 1200;
export const CATAPULT_SPEED_MULT      = 0.65;
export const CATAPULT_REARM_MS        = 800;   // delay before rock spawns (frame 4 of 5 @ 5fps)
export const CATAPULT_MIN_TARGET_DIST = 220;   // min dist from tower contact

// ─── Outpost base stats ───────────────────────────────────────────────────────
export const OUTPOST_FIRE_RATE_BASE    = 0.55;
export const OUTPOST_DAMAGE_SCALE_BASE = 0.85;
export const OUTPOST_WAVE_HP_SCALE     = 1.2;
export const OUTPOST_WAVE_DAMAGE_SCALE = 0.55;

// ─── Upgrade steps (using Godot scene overrides) ──────────────────────────────
export const DAMAGE_UPGRADE_STEP          = 10;    // scene override (script: 2)
export const SPEED_UPGRADE_STEP           = 0.08;
export const TOWER_HP_UPGRADE_STEP        = 40;
export const OUTPOST_HP_UPGRADE_STEP      = 25;
export const OUTPOST_DAMAGE_UPGRADE_STEP  = 0.08;
export const CATAPULT_DAMAGE_UPGRADE_STEP = 8;
export const CATAPULT_SPEED_UPGRADE_STEP  = 0.04;
export const CATAPULT_AOE_UPGRADE_STEP    = 15;

// ─── Speed toggle ─────────────────────────────────────────────────────────────
export const SPEED_UP_SCALE = 2.0;

// ─── Orc spritesheet (100×100 per frame, 8 columns) ──────────────────────────
//   Row 0 (y=0):   frames  0- 7  — unused/other
//   Row 1 (y=100): frames  8-15  — walk (8 frames)
//   Row 2 (y=200): frames 16-23  — attack (6 frames, 22-23 empty)
//   Row 5 (y=500): frames 40-47  — die (4 frames, 44-47 empty)
export const ORC_FRAME_W     = 100;
export const ORC_FRAME_H     = 100;
export const ORC_SHEET_COLS  = 8;
export const ORC_WALK_FRAMES   = [8, 9, 10, 11, 12, 13, 14, 15];
export const ORC_ATTACK_FRAMES = [16, 17, 18, 19, 20, 21];
export const ORC_DIE_FRAMES    = [40, 41, 42, 43];
export const ORC_ANIM_FPS      = 5;

// ─── Upgrade XP costs ─────────────────────────────────────────────────────────
export const UPGRADE_COSTS: Record<string, number> = {
  archer_power:      75,
  archer_speed:      75,
  tower_health:      60,
  tower_archers:     150,
  catapult_unlocked: 300,
  catapult_power:    100,
  catapult_speed:    100,
  catapult_aoe:      100,
  outpost_unlocked:  400,
  outpost_archers:   150,
  outpost_strength:  80,
  outpost_power:     100,
  outpost_speed:     100,
};

// ─── Phase 2 XP hooks ─────────────────────────────────────────────────────────
import { getSupabaseClient } from './lib/supabase';

/**
 * Checks XP balance and deducts the cost if affordable.
 * Returns true if the upgrade should proceed (including offline fallback).
 * Returns false if the user has insufficient XP.
 */
export async function spendXPAsync(key: string): Promise<boolean> {
  const cost = UPGRADE_COSTS[key];
  if (cost === undefined) return false;

  const sb = getSupabaseClient();
  if (!sb) return true; // no Supabase client = offline fallback, allow upgrade

  const { data: events } = await sb.from('xp_events').select('delta');
  if (!events) return true; // network error fallback

  const total = events.reduce((s: number, r: { delta: number }) => s + r.delta, 0);
  if (total < cost) return false;

  const { data: { user } } = await sb.auth.getUser();
  if (!user) return true; // not authenticated fallback

  const { error } = await sb.from('xp_events').insert({
    user_id: user.id,
    type: 'spend',
    delta: -cost,
    source: `upgrade:${key}`,
  });

  return !error;
}

// Keep synchronous stubs (imported elsewhere but no longer used for gating)
export function canAffordUpgrade(_key: string): boolean { return true; }
export function spendXP(_amount: number): void { /* noop */ }

// ─── Ballistic velocity helper ────────────────────────────────────────────────
export function ballisticVelocity(
  start: { x: number; y: number },
  target: { x: number; y: number },
  speedHint: number,
  gravity: number,
  minT = MIN_SHOT_TIME,
  maxT = MAX_SHOT_TIME,
): { vx: number; vy: number } {
  const dx = target.x - start.x;
  const dy = target.y - start.y;
  const dist = Math.max(1, Math.sqrt(dx * dx + dy * dy));
  const t = Math.max(minT, Math.min(maxT, dist / Math.max(1, speedHint)));
  return { vx: dx / t, vy: (dy - 0.5 * gravity * t * t) / t };
}
