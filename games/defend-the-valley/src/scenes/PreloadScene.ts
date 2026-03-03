import Phaser from 'phaser';
import { ORC_FRAME_W, ORC_FRAME_H, ORC_SHEET_COLS } from '../constants';
import { getSupabaseClient } from '../lib/supabase';

export class PreloadScene extends Phaser.Scene {
  constructor() { super('PreloadScene'); }

  preload(): void {
    // Progress bar
    const { width: W, height: H } = this.scale;
    const bar = this.add.graphics();
    const barW = 400, barH = 20;
    const bx = W / 2 - barW / 2, by = H / 2 - barH / 2;

    this.add.text(W / 2, H / 2 - 40, 'Loading…', {
      fontFamily: 'monospace', fontSize: '22px', color: '#ffffff',
    }).setOrigin(0.5);

    this.load.on('progress', (v: number) => {
      bar.clear();
      bar.fillStyle(0x222244);
      bar.fillRect(bx, by, barW, barH);
      bar.fillStyle(0x4488ff);
      bar.fillRect(bx, by, barW * v, barH);
    });

    // Background
    this.load.image('bg', 'art/background/Background.png');

    // Tower sprites
    this.load.image('tower',  'art/tower/tower.png');
    this.load.image('tower2', 'art/tower/2nd tower.png');

    // Enemy spritesheet (100×100 frames, 8 columns)
    this.load.spritesheet('orc', 'art/enemies/Orc.png', {
      frameWidth: ORC_FRAME_W,
      frameHeight: ORC_FRAME_H,
    });

    // Catapult frames (individual images)
    this.load.image('catapult1', 'art/catapult/1-1.png');
    this.load.image('catapult2', 'art/catapult/1-2.png');
    this.load.image('catapult3', 'art/catapult/1-3.png');
    this.load.image('catapult4', 'art/catapult/1-4.png');

    // Catapult rock (boulder)
    this.load.image('boulder', 'art/catapultrock/boulder.png');

    // Explosion frames (individual images)
    for (let i = 1; i <= 10; i++) {
      this.load.image(`explosion${i}`, `art/catapultrock/Explosion${i}.png`);
    }

    // Arrow projectile
    this.load.image('arrow', 'art/projectiles/Arrow01(32x32).png');

    // Suppress unused variable warning — ORC_SHEET_COLS used implicitly
    void ORC_SHEET_COLS;
  }

  create(): void {
    getSupabaseClient(); // warm up singleton so first upgrade click has no cold-start delay
    this.scene.start('MenuScene');
  }
}
