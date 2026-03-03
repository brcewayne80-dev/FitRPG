#!/usr/bin/env node
/**
 * FitRPG Flare XP Launcher
 * -------------------------
 * 1. Read current XP balance from Supabase
 * 2. Write it into Flare's save file as gold
 * 3. Launch Flare and wait for it to exit
 * 4. Read remaining gold, record the difference as a spend event
 *
 * Usage: node flare-launcher.js --token=<supabase_jwt>
 */

'use strict';

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://yjcgtytdemtdawoepazo.supabase.co';
const SUPABASE_ANON_KEY = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_x4qlPXC0_2lDCYKsAQB7aw_5WQnGiBu';
const FLARE_SAVE_DIR = path.join(process.env.HOME || '/home/pi', '.local', 'share', 'flare', 'saves');
const FLARE_SAVE_FILE = path.join(FLARE_SAVE_DIR, '1.sav');

// Parse --token=<jwt> argument
const tokenArg = process.argv.find((a) => a.startsWith('--token='));
const token = tokenArg ? tokenArg.slice('--token='.length) : null;

async function main() {
  let client = null;
  let userId = null;
  let xpBalance = 0;

  if (token) {
    client = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      auth: { persistSession: false, autoRefreshToken: false },
      global: { headers: { Authorization: `Bearer ${token}` } },
    });

    const { data: { user } } = await client.auth.getUser();
    if (user) {
      userId = user.id;
      const { data } = await client
        .from('xp_events')
        .select('delta')
        .eq('user_id', userId);
      if (data) {
        xpBalance = data.reduce((sum, row) => sum + row.delta, 0);
      }
    }
  }

  // Write XP balance as gold into Flare save (if save exists)
  if (userId && fs.existsSync(FLARE_SAVE_FILE)) {
    let save = fs.readFileSync(FLARE_SAVE_FILE, 'utf8');
    if (/^gold=/m.test(save)) {
      save = save.replace(/^gold=\d+/m, `gold=${xpBalance}`);
    } else {
      save += `\ngold=${xpBalance}\n`;
    }
    fs.writeFileSync(FLARE_SAVE_FILE, save, 'utf8');
    console.log(`[FitRPG] Set Flare gold to ${xpBalance} (current XP balance)`);
  }

  // Launch Flare and wait
  console.log('[FitRPG] Launching Flare...');
  spawnSync('flare', [], { stdio: 'inherit' });
  console.log('[FitRPG] Flare exited.');

  // Read remaining gold and record spend
  if (userId && client && fs.existsSync(FLARE_SAVE_FILE)) {
    const saveAfter = fs.readFileSync(FLARE_SAVE_FILE, 'utf8');
    const match = saveAfter.match(/^gold=(\d+)/m);
    const newGold = match ? parseInt(match[1], 10) : xpBalance;
    const spent = xpBalance - newGold;

    if (spent > 0) {
      await client.from('xp_events').insert({
        user_id: userId,
        type: 'spend',
        delta: -spent,
        source: 'flare',
        ts: new Date().toISOString(),
      });
      console.log(`[FitRPG] Recorded ${spent} XP spent in Flare.`);
    } else {
      console.log('[FitRPG] No XP spent this session.');
    }
  }
}

main().catch((e) => {
  console.error('[FitRPG] flare-launcher error:', e);
  process.exit(1);
});
